WITH OrderDetails AS (
    SELECT 
        oh.ORDER_ID,
        oi.PRODUCT_ID,
        oi.ORDER_ITEM_SEQ_ID
    FROM order_header oh
    INNER JOIN order_item oi ON oi.ORDER_ID = oh.ORDER_ID AND oi.status_id = 'ITEM_COMPLETED'
    JOIN order_identification oid ON oh.ORDER_ID = oid.ORDER_ID AND oid.ORDER_IDENTIFICATION_TYPE_ID = 'SHOPIFY_ORD_NAME'
    LEFT JOIN product p ON oi.PRODUCT_ID = p.PRODUCT_ID
    WHERE oh.PRODUCT_STORE_ID = 'BJ_STORE' 
      AND oh.ORDER_TYPE_ID = 'SALES_ORDER'
      AND p.PRODUCT_TYPE_ID = 'FINISHED_GOOD'
),
ShippingDetails AS (
    SELECT 
        osh.ORDER_ID,
        osh.ORDER_ITEM_SEQ_ID,
        ss.STATUS_DATE AS SHIPPED_DATE
    FROM order_shipment osh
    JOIN shipment_status ss ON osh.SHIPMENT_ID = ss.SHIPMENT_ID 
    WHERE ss.STATUS_ID = 'SHIPMENT_SHIPPED'
),
RevenueCalculations AS (
    SELECT 
        ori.ORDER_ID,
        ori.ORDER_ITEM_SEQ_ID,
        ori.UNIT_PRICE,
        (ori.QUANTITY - IFNULL(ori.CANCEL_QUANTITY, 0)) AS ITEM_QTY,
        ROUND(
            (SELECT SUM(AMOUNT) 
             FROM order_adjustment 
             WHERE ORDER_ID = ori.ORDER_ID 
               AND ORDER_ITEM_SEQ_ID = ori.ORDER_ITEM_SEQ_ID 
               AND ORDER_ADJUSTMENT_TYPE_ID IN ('EXT_PROMO_ADJUSTMENT')
            ) / (ori.QUANTITY - IFNULL(ori.CANCEL_QUANTITY, 0)), 
            2
        ) AS ITEM_DISC_PER_UNIT,
        ROUND(
            (SELECT SUM(AMOUNT) 
             FROM order_adjustment 
             WHERE ORDER_ID = ori.ORDER_ID 
               AND ORDER_ITEM_SEQ_ID = ori.ORDER_ITEM_SEQ_ID 
               AND ORDER_ADJUSTMENT_TYPE_ID = 'SALES_TAX'
            ), 
            2
        ) AS ITEM_TAX_AMOUNT
    FROM order_item ori
    INNER JOIN order_header oh ON ori.ORDER_ID = oh.ORDER_ID
    WHERE ori.STATUS_ID = 'ITEM_COMPLETED' 
      AND oh.PRODUCT_STORE_ID = 'BJ_STORE' 
      AND oh.ORDER_TYPE_ID = 'SALES_ORDER'
),ProductDetails AS (
    SELECT 
        p.PRODUCT_ID,
        COALESCE(pp.PRODUCT_NAME, p.PRODUCT_NAME) AS ITEM_DESC
    FROM product p
    LEFT JOIN product_assoc pas ON p.PRODUCT_ID = pas.PRODUCT_ID_TO AND pas.PRODUCT_ASSOC_TYPE_ID = 'PRODUCT_VARIANT'
    LEFT JOIN product pp ON pas.PRODUCT_ID = pp.PRODUCT_ID
)
SELECT 
    sum(ROUND((rc.UNIT_PRICE + IFNULL(rc.ITEM_DISC_PER_UNIT, 0)), 2)) AS REVENUE,
    sum(rc.ITEM_TAX_AMOUNT) AS SALES_TAX_TOTAL
FROM OrderDetails od
LEFT JOIN ShippingDetails sd ON od.ORDER_ID = sd.ORDER_ID AND od.ORDER_ITEM_SEQ_ID = sd.ORDER_ITEM_SEQ_ID
LEFT JOIN RevenueCalculations rc ON od.ORDER_ID = rc.ORDER_ID AND od.ORDER_ITEM_SEQ_ID = rc.ORDER_ITEM_SEQ_ID
LEFT JOIN ProductDetails pd ON od.PRODUCT_ID = pd.PRODUCT_ID
WHERE DATE(sd.SHIPPED_DATE) BETWEEN '2024-02-01' AND '2024-02-28';
