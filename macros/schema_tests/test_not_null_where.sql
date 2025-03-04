{% test not_null_where(model, column_name) %}
  {%- set deprecation_warning = '
    Warning: `cc_dbt_utils.not_null_where` is no longer supported.
    Starting in dbt v0.20.0, the built-in `not_null` test supports a `where` config.
    ' -%}
  {%- do exceptions.warn(deprecation_warning) -%}
  {{ return(adapter.dispatch('test_not_null_where', 'cc_dbt_utils')(model, column_name)) }}
{% endtest %}

{% macro default__test_not_null_where(model, column_name) %}
  {{ return(test_not_null(model, column_name)) }}
{% endmacro %}
