{% macro hash(field) -%}
  {{ return(adapter.dispatch('hash', 'cc_dbt_utils') (field)) }}
{%- endmacro %}


{% macro default__hash(field) -%}
    md5(cast({{field}} as {{cc_dbt_utils.type_string()}}))
{%- endmacro %}


{% macro bigquery__hash(field) -%}
    to_hex({{cc_dbt_utils.default__hash(field)}})
{%- endmacro %}
