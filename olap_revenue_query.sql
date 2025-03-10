WITH OrderDetails AS (
    SELECT 
        oiff.ORDER_ID,
        oiff.ORDER_ITEM_SEQ_ID
    FROM order_item_fulfillment_fact oiff
      WHERE oiff.ITEM_STATUS_ID = 'ITEM_COMPLETED'
     AND oiff.PRODUCT_STORE_ID = 'BJ_STORE' 
      AND oiff.ORDER_TYPE_ID = 'SALES_ORDER'
),
ShippingDetails AS (
    SELECT 
        oiff.ORDER_ID,
        oiff.ORDER_ITEM_SEQ_ID,
        oiff.SHIPMENT_SHIPPED_DATE AS SHIPPED_DATE
    FROM order_item_fulfillment_fact oiff
    WHERE oiff.SHIPMENT_SHIPPED_DATE IS NOT NULL
),
RevenueCalculations AS (
    SELECT 
        oiff.ORDER_ID,
        oiff.ORDER_ITEM_SEQ_ID,
        oiff.UNIT_PRICE,
        (oiff.QUANTITY - IFNULL(oiff.CANCEL_QUANTITY, 0)) AS ITEM_QTY,
        ROUND(
            (SELECT SUM(oaf.EXT_PROMO_ADJUSTMENT) 
             FROM order_adjustment_fact oaf
             WHERE oaf.ORDER_ID = oiff.ORDER_ID 
               AND oaf.ORDER_ITEM_SEQ_ID = oiff.ORDER_ITEM_SEQ_ID 
               AND oaf.EXT_PROMO_ADJUSTMENT IS NOT NULL
            ) / (oiff.QUANTITY - IFNULL(oiff.CANCEL_QUANTITY, 0)), 
            2
        ) AS ITEM_DISC_PER_UNIT,
        ROUND(
            (SELECT SUM(oaf.SHIPPING_SALES_TAX) 
             FROM order_adjustment_fact oaf
             WHERE oaf.ORDER_ID = oiff.ORDER_ID 
               AND oaf.ORDER_ITEM_SEQ_ID = oiff.ORDER_ITEM_SEQ_ID
            ), 
            2
        ) AS ITEM_TAX_AMOUNT
    FROM order_item_fulfillment_fact oiff
    WHERE oiff.ITEM_STATUS_ID = 'ITEM_COMPLETED'
      AND oiff.PRODUCT_STORE_ID = 'BJ_STORE' 
      AND oiff.ORDER_TYPE_ID = 'SALES_ORDER'
)
SELECT 
    SUM(ROUND((rc.UNIT_PRICE + IFNULL(rc.ITEM_DISC_PER_UNIT, 0)), 2)) AS REVENUE,
    SUM(rc.ITEM_TAX_AMOUNT) AS SALES_TAX_TOTAL
FROM OrderDetails od
LEFT JOIN ShippingDetails sd ON od.ORDER_ID = sd.ORDER_ID AND od.ORDER_ITEM_SEQ_ID = sd.ORDER_ITEM_SEQ_ID
LEFT JOIN RevenueCalculations rc ON od.ORDER_ID = rc.ORDER_ID AND od.ORDER_ITEM_SEQ_ID = rc.ORDER_ITEM_SEQ_ID
WHERE DATE(sd.SHIPPED_DATE) BETWEEN '2025-02-01' AND '2025-02-28';
