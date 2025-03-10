with return_info as (
    select
        DISTINCT ri.ORDER_ID,
        ri.ORDER_ITEM_SEQ_ID,
        cast(rh.return_date as date) as RETURN_DATE,
        ri.RETURN_PRICE as RETURN_ITEM,
        (
            select sum(ra.amount)
            from return_adjustment ra
            where
                ri.RETURN_ID = ra.RETURN_ID
                and ri.RETURN_ITEM_SEQ_ID = ra.RETURN_ITEM_SEQ_ID
                and ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_EXT_PRM_ADJ'
                and ra.RETURN_TYPE_ID = 'RTN_REFUND'
        ) as DISCOUNT,
        (
            case
                when ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_SALES_TAX_ADJ' then ra.AMOUNT
                else 0
            end + case
                when ra.RETURN_ADJUSTMENT_TYPE_ID = 'RET_SHIPPING_ADJ' and ra.RETURN_TYPE_ID = 'RTN_REFUND' then ra.AMOUNT
                else 0
            end
        ) as TOTAL_TAX_REFUND,
        (ri.RETURN_PRICE) + ifnull(ra.amount , 0) as RETURNED_TOTAL
    from
        return_item ri
    left join return_adjustment ra on
        ri.RETURN_ID = ra.RETURN_ID
        and ri.RETURN_ITEM_SEQ_ID = ra.RETURN_ITEM_SEQ_ID
    join order_header oh on
        ri.ORDER_ID = oh.ORDER_ID
    join return_header rh on
        ri.RETURN_ID = rh.return_id
    join order_item oi2 on
        oi2.ORDER_ID = ri.ORDER_ID
        and oi2.ORDER_ITEM_SEQ_ID = ri.ORDER_ITEM_SEQ_ID
    join order_shipment os on
        oi2.ORDER_ID = os.ORDER_ID
        and oi2.ORDER_ITEM_SEQ_ID = os.ORDER_ITEM_SEQ_ID
    join shipment_status ss on
        os.SHIPMENT_ID = ss.SHIPMENT_ID
        and ss.STATUS_ID = 'SHIPMENT_SHIPPED'
    where
        ri.STATUS_ID = 'RETURN_COMPLETED'
        and oh.PRODUCT_STORE_ID = 'BJ_STORE'
        and DATE(rh.return_date) between '2025-02-01' and '2025-02-28'
)
select
    sum(ri.RETURN_ITEM),
    sum(ri.DISCOUNT),
    sum(ri.TOTAL_TAX_REFUND),
    sum(ri.RETURNED_TOTAL)
from
    return_info ri
order by
    ri.RETURN_DATE;
