{% macro intersect() %}
  {{ adapter.dispatch('intersect', packages = cc_dbt_utils._get_utils_namespaces())() }}
{% endmacro %}


{% macro default__intersect() %}

    intersect

{% endmacro %}

{% macro bigquery__intersect() %}

    intersect distinct

{% endmacro %}
