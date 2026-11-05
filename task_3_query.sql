SELECT 
    co.order_number AS "Номер заказа",
    p.name AS "Наименование продукции",
    coi.quantity AS "Количество в заказе, шт",
    SUM(si.norm_quantity * r.unit_price) AS "Себестоимость 1 шт., руб.",
    SUM(si.norm_quantity * r.unit_price) * coi.quantity AS "Полная стоимость заказа, руб."
FROM 
    customer_orders co
    JOIN customer_order_items coi ON co.id_order = coi.id_order
    JOIN products p ON coi.id_product = p.id_product
    JOIN specifications spec ON p.id_product = spec.id_product
    JOIN specification_items si ON spec.id_specification = si.id_specification
    JOIN resources r ON si.id_resource = r.id_resource
WHERE 
    co.order_number = 'ЗП-0001'
GROUP BY 
    co.order_number, 
    p.name, 
    coi.quantity;