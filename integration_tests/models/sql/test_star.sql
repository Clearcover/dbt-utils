{% set exclude_field = 'field_3' %}


with data as (

    select
        {{ cc_dbt_utils.star(from=ref('data_star'), except=[exclude_field]) }}

    from {{ ref('data_star') }}

)

select * from data
