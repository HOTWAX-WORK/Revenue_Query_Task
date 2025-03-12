WITH REVENUE AS
  (SELECT SUM(ROUND((oiff.UNIT_PRICE + IFNULL(oiff.ITEM_DISC_PER_UNIT, 0)), 2)) AS REVENUE,
          SUM(IFNULL(oiff.ITEM_TAX_AMOUNT, 0)) AS SALES_TAX_TOTAL
   FROM order_item_fulfillment_fact oiff
   WHERE oiff.PRODUCT_STORE_ID = 'BJ_STORE'
     AND oiff.ORDER_TYPE_ID = 'SALES_ORDER'
     AND oiff.ITEM_STATUS_ID = 'ITEM_COMPLETED'
     AND oiff.SHIPMENT_SHIPPED_DATE IS NOT NULL
     AND DATE(oiff.SHIPMENT_SHIPPED_DATE) BETWEEN '2025-02-01' AND '2025-02-28'
  ), 
  RETURN_REV AS
  (SELECT SUM(IFNULL(rif.RETURN_PRICE, 0)) AS TOTAL_RETURN_ITEM,
          SUM(IFNULL(rif.RETURN_DISCOUNT_AMT, 0)) AS TOTAL_DISCOUNT,
          SUM(IFNULL(rif.TOTAL_TAX_REFUND_AMT, 0)) AS TOTAL_TAX_REFUND,
          SUM(IFNULL(rif.RETURN_PRICE, 0) + IFNULL(rif.TOTAL_TAX_REFUND_AMT, 0)) AS TOTAL_RETURNED_AMOUNT
   FROM return_item_fact rif
   WHERE rif.RETURN_STATUS_ID = 'RETURN_COMPLETED'
     AND rif.PRODUCT_STORE_ID = 'BJ_STORE'
     AND DATE(rif.RETURN_DATE) BETWEEN '2025-02-01' AND '2025-02-28'
  )

SELECT (R.REVENUE - (RR.TOTAL_RETURN_ITEM + RR.TOTAL_DISCOUNT)) AS ITEM_REVENUE,
       (R.SALES_TAX_TOTAL - RR.TOTAL_TAX_REFUND) AS TAX_REVENUE
FROM REVENUE R,
     RETURN_REV RR;
