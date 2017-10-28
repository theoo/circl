DROP FUNCTION IF EXISTS person_affairs_as_tree();
CREATE FUNCTION person_affairs_as_tree() RETURNS table(
  id int,
  parent_id int,
  owner_id int,
  receiver_id int,
  seller_id int,
  buyer_id int,
  condition_id int,
  title text,
  value_in_cents bigint,
  value_currency varchar,
  vat_in_cents int,
  vat_currency varchar,
  sold_at timestamp,
  created_at timestamp,
  updated_at timestamp,
  status int,
  estimate boolean,
  archive boolean,
  sort integer[]
   ) AS $$

  WITH RECURSIVE tree AS
    ( SELECT
        affairs.id,
        affairs.parent_id,
        affairs.owner_id,
        affairs.receiver_id,
        affairs.seller_id,
        affairs.buyer_id,
        affairs.condition_id,
        affairs.title,
        affairs.value_in_cents,
        affairs.value_currency,
        affairs.vat_in_cents,
        affairs.vat_currency,
        affairs.sold_at,
        affairs.created_at,
        affairs.updated_at,
        affairs.status,
        affairs.estimate,
        affairs.archive,
        array[affairs.id] as sort
      FROM affairs
      WHERE parent_id is null
    UNION ALL
      SELECT
        a.id,
        a.parent_id,
        a.owner_id,
        a.receiver_id,
        a.seller_id,
        a.buyer_id,
        a.condition_id,
        a.title,
        a.value_in_cents,
        a.value_currency,
        a.vat_in_cents,
        a.vat_currency,
        a.sold_at,
        a.created_at,
        a.updated_at,
        a.status,
        a.estimate,
        a.archive,
        t.sort || a.id
      FROM tree t, affairs a
      WHERE a.parent_id = t.id )

SELECT * FROM tree t ORDER BY t.sort DESC
$$ LANGUAGE SQL;
