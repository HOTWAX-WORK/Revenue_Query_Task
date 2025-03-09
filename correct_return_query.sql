WITH ReturnDetails AS (
    SELECT 
        ri.RETURN_ID,
        ri.ORDER_ID AS HC_ORDER_ID,
        ri.ORDER_ITEM_SEQ_ID AS HC_ORDER_ITEM_SEQ_ID,
        ri.RETURN_PRICE AS RETURN_ITEM,
        rh.RETURN_DATE
    FROM return_item ri
    JOIN return_header rh ON ri.RETURN_ID = rh.RETURN_ID
    WHERE ri.STATUS_ID = 'RETURN_COMPLETED'
),
OrderDetails AS (
    SELECT 
        oh.ORDER_ID
    FROM order_header oh
    WHERE oh.PRODUCT_STORE_ID = 'BJ_STORE'
),
ShipmentDetails AS (
    SELECT 
        os.ORDER_ID,
        os.ORDER_ITEM_SEQ_ID,
        CAST(ss.STATUS_DATE AS DATE) AS SHIP_DATE
    FROM order_shipment os
    JOIN shipment_status ss ON os.SHIPMENT_ID = ss.SHIPMENT_ID 
    WHERE ss.STATUS_ID = 'SHIPMENT_SHIPPED'
),
ReturnAdjustments AS (
    SELECT 
        ra.RETURN_ID,
        ra.RETURN_ITEM_SEQ_ID,
        SUM(CASE WHEN ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_EXT_PRM_ADJ' AND ra.RETURN_TYPE_ID = 'RTN_REFUND' 
                 THEN ra.AMOUNT ELSE 0 END) AS DISCOUNT,
        SUM(CASE WHEN ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_SALES_TAX_ADJ' 
                 THEN ra.AMOUNT ELSE 0 END) +
        SUM(CASE WHEN ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_SHIPPING_ADJ' 
                 AND ra.RETURN_TYPE_ID = 'RTN_REFUND' THEN ra.AMOUNT ELSE 0 END) AS TOTAL_TAX_REFUND
    FROM return_adjustment ra
    GROUP BY ra.RETURN_ID, ra.RETURN_ITEM_SEQ_ID
),
ReturnIdentification AS (
    SELECT 
        rii.RETURN_ID,
        rii.ID_VALUE AS SHOPIFY_RETURN_ID
    FROM return_identification rii
    WHERE rii.RETURN_IDENTIFICATION_TYPE_ID = 'SHOPIFY_RTN_ID'
)
SELECT DISTINCT 
    sum(ra.DISCOUNT),
    sum(ra.TOTAL_TAX_REFUND),
    sum(rd.RETURN_ITEM + IFNULL(ra.DISCOUNT, 0)) AS RETURNED_TOTAL
FROM ReturnDetails rd
JOIN OrderDetails od ON rd.HC_ORDER_ID = od.ORDER_ID
JOIN ShipmentDetails sd ON rd.HC_ORDER_ID = sd.ORDER_ID AND rd.HC_ORDER_ITEM_SEQ_ID = sd.ORDER_ITEM_SEQ_ID
LEFT JOIN ReturnAdjustments ra ON rd.RETURN_ID = ra.RETURN_ID AND rd.HC_ORDER_ITEM_SEQ_ID = ra.RETURN_ITEM_SEQ_ID
LEFT JOIN ReturnIdentification ri2 ON rd.RETURN_ID = ri2.RETURN_ID
JOIN order_item oi2 ON rd.HC_ORDER_ID = oi2.ORDER_ID AND rd.HC_ORDER_ITEM_SEQ_ID = oi2.ORDER_ITEM_SEQ_ID
and rd.return_date BETWEEN '2023-05-01' AND '2024-05-31'
ORDER BY rd.RETURN_DATE;
