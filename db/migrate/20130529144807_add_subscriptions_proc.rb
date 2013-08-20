class AddSubscriptionsProc < ActiveRecord::Migration
  def up
    execute("CREATE OR REPLACE FUNCTION subscriptions_as_tree() RETURNS table(
    id int,
    parent_id int,
    title text,
    description text,
    interval_starts_on date,
    interval_ends_on date,
    value_in_cents int,
    value_currency text,
    invoice_template_id int,
    created_at timestamp,
    updated_at timestamp,
    sort integer[]
     ) AS $$

    WITH RECURSIVE tree AS
      ( SELECT
          subscriptions.id,
          subscriptions.parent_id,
          subscriptions.title,
          subscriptions.description,
          subscriptions.interval_starts_on,
          subscriptions.interval_ends_on,
          subscriptions.value_in_cents,
          subscriptions.value_currency,
          subscriptions.invoice_template_id,
          subscriptions.created_at,
          subscriptions.updated_at,
          array[subscriptions.id] as sort
        FROM subscriptions
        WHERE parent_id is null
      UNION ALL
        SELECT
          s.id,
          s.parent_id,
          s.title,
          s.description,
          s.interval_starts_on,
          s.interval_ends_on,
          s.value_in_cents,
          s.value_currency,
          s.invoice_template_id,
          s.created_at,
          s.updated_at,
          t.sort || s.id
        FROM tree t, subscriptions s
        WHERE s.parent_id = t.id )
  SELECT * FROM tree t ORDER BY t.sort DESC
  $$ LANGUAGE SQL;")
  end

  def down
    execute "DROP FUNCTION subscriptions_as_tree();"
  end
end
