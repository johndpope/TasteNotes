-- This script was generated by the Schema Diff utility in pgAdmin 4
-- For the circular dependencies, the order in which Schema Diff writes the objects is not very sophisticated
-- and may require manual changes to the script to ensure changes are applied in the correct order.
-- Please report an issue for any failure with the reproduction steps.

CREATE OR REPLACE FUNCTION public.fnc__create_product(IN p_name text,IN p_description text,IN p_category_id bigint,IN p_sub_category_ids bigint[],IN p_brand_id bigint,IN p_sub_brand_id bigint DEFAULT NULL::bigint)
    RETURNS SETOF products
    LANGUAGE 'plpgsql'
    VOLATILE
    PARALLEL UNSAFE
    COST 100    ROWS 1000 
    
AS $BODY$
DECLARE
  v_product_id   bigint;
  v_sub_brand_id bigint;
  v_product_name text;
  v_product_description text;
BEGIN
  if trim(p_name) = '' then
    raise exception 'product name can`t be empty' using errcode = 'no_name';
  else
    v_product_name = trim(p_name);
  end if;

  if trim(p_description) = '' then
    v_product_description = null;
  else
    v_product_description = trim(p_description);
  end if;

  if p_sub_brand_id is null then
    insert into sub_brands (name, brand_id, created_by)
    values (null, p_brand_id, auth.uid())
    returning id into v_sub_brand_id;
  else
    v_sub_brand_id = p_sub_brand_id;
  end if;

  insert into products (name, description, category_id, sub_brand_id, created_by)
  values (v_product_name, v_product_description, p_category_id, v_sub_brand_id, auth.uid())
  returning id into v_product_id;

  with subcategories_for_product as (select unnest(p_sub_category_ids) subcategory_id, v_product_id product_id)
  insert
  into products_subcategories (product_id, subcategory_id, created_by)
  select product_id, subcategory_id, auth.uid() created_by
  from subcategories_for_product;

  return query (select *
                from products
                where id = v_product_id);
END

$BODY$;

REVOKE ALL ON TABLE public.product_variants FROM anon;
REVOKE ALL ON TABLE public.product_variants FROM postgres;
REVOKE ALL ON TABLE public.product_variants FROM service_role;
GRANT ALL ON TABLE public.product_variants TO anon;

GRANT ALL ON TABLE public.product_variants TO service_role;

GRANT ALL ON TABLE public.product_variants TO postgres;

REVOKE ALL ON TABLE public.product_edit_suggestions FROM anon;
REVOKE ALL ON TABLE public.product_edit_suggestions FROM postgres;
REVOKE ALL ON TABLE public.product_edit_suggestions FROM service_role;
GRANT ALL ON TABLE public.product_edit_suggestions TO anon;

GRANT ALL ON TABLE public.product_edit_suggestions TO service_role;

GRANT ALL ON TABLE public.product_edit_suggestions TO postgres;

REVOKE ALL ON TABLE public.profiles FROM anon;
REVOKE ALL ON TABLE public.profiles FROM service_role;
REVOKE ALL ON TABLE public.profiles FROM postgres;
GRANT ALL ON TABLE public.profiles TO anon;

GRANT ALL ON TABLE public.profiles TO postgres;

GRANT ALL ON TABLE public.profiles TO service_role;

REVOKE ALL ON TABLE public.notifications FROM anon;
REVOKE ALL ON TABLE public.notifications FROM postgres;
REVOKE ALL ON TABLE public.notifications FROM service_role;
GRANT ALL ON TABLE public.notifications TO anon;

GRANT ALL ON TABLE public.notifications TO service_role;

GRANT ALL ON TABLE public.notifications TO postgres;

REVOKE ALL ON TABLE public.companies FROM anon;
REVOKE ALL ON TABLE public.companies FROM postgres;
REVOKE ALL ON TABLE public.companies FROM service_role;
GRANT ALL ON TABLE public.companies TO anon;

GRANT ALL ON TABLE public.companies TO service_role;

GRANT ALL ON TABLE public.companies TO postgres;

REVOKE ALL ON TABLE public.sub_brands FROM authenticated;
REVOKE ALL ON TABLE public.sub_brands FROM postgres;
REVOKE ALL ON TABLE public.sub_brands FROM service_role;
GRANT ALL ON TABLE public.sub_brands TO authenticated;

GRANT ALL ON TABLE public.sub_brands TO service_role;

GRANT ALL ON TABLE public.sub_brands TO postgres;