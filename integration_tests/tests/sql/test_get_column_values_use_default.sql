
{% set column_values = cc_dbt_utils.get_column_values(ref('data_get_column_values_dropped'), 'field', default=['y', 'z'], order_by="field") %}

with expected as (
    select {{ cc_dbt_utils.safe_cast("'y'", cc_dbt_utils.type_string()) }} as expected_column_value union all
    select {{ cc_dbt_utils.safe_cast("'z'", cc_dbt_utils.type_string()) }} as expected_column_value
),

actual as (
     
        {% for val in column_values %}
            select {{ cc_dbt_utils.safe_cast("'" ~ val ~ "'", cc_dbt_utils.type_string()) }} as actual_column_value
            {% if not loop.last %}
                union all
            {% endif %}
        {% endfor %}
),

failures as (
    select * from actual
    where actual.actual_column_value not in (
        select expected.expected_column_value from expected
    )
)

select * from failures