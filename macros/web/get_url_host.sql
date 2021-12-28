{% macro get_url_host(field) -%}

{%- set parsed =
    dbt_utils.split_part(
        dbt_utils.split_part(
            dbt_utils.replace(
                dbt_utils.replace(
                    dbt_utils.replace(field, "'android-app://'", "''"
                    ), "'http://'", "''"
                ), "'https://'", "''"
            ), "'/'", 1
        ), "'?'", 1
    )

-%}

     
    {{ cc_dbt_utils.safe_cast(
        parsed,
        cc_dbt_utils.type_string()
        )}}

{%- endmacro %}
