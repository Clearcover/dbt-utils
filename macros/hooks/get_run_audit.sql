{% macro get_run_audit(results, flags, target) %}
    {{ return(adapter.dispatch('get_run_audit', 'cc_dbt_utils')(results, flags, target)) }}
{% endmacro %}

{% macro default__get_run_audit(results, flags, target) %}
{#
This macro gets back a dictionary like:
    {
        'run_results': [
            {
                'name': 'stg_customers',
                'unique_id': 'model.jaffle_shop.stg_customers',
                'resource_type': 'model',
                'package': 'jaffle_shop',
                'schema': 'jaffle_shop',
                'database': 'analytics',
                'materialized': 'table',
                'warehouse': 'transforming',
                'status': 'success',
                'message': 'CREATE TABLE',
                'execution_time': 1.23,
                'rows_affected': 500,
                'thread_id': 'Thread-1',
                'tags': ['daily', 'external_reporting'],
                'failures': '',
                'invocation_id': 'abc-123',
                'timing': {
                    'started_at': '2019-05-03 22:20:16:315020',
                    'completed_at': '2019-05-03 22:20:16:716081'
                }
            }
        ],
        'target': {
            'name': 'dev',
            'user': 'claire',
            'database': 'claire',
            'schema': 'jaffle_shop_dev'
        },
        'flags': {
            'full_refresh': False
        }
    }
 #}
{% set run_audit={} %}

{% set run_results=[] %}

{% for result in results %}

    {% if result.skipped == False %}

        {% set model_result={} %}
        {% set materialization = result.node.config.get("materialized", "") %}
        {% set warehouse = result.node.config.get("snowflake_warehouse", "") %}

        {% do model_result.update({'name': result.node.name}) %}
        {% do model_result.update({'unique_id': result.node.unique_id}) %}
        {% do model_result.update({'resource_type': result.node.resource_type}) %}
        {% do model_result.update({'package': result.node.package_name}) %}
        {% do model_result.update({'schema': result.node.schema}) %}
        {% do model_result.update({'database': result.node.database}) %}
        {% do model_result.update({'materialized': materialization}) %}
        {% do model_result.update({'warehouse': warehouse or ''}) %}
        {% do model_result.update({'status': result.status}) %}
        {% do model_result.update({'message': result.message or ''}) %}
        {% do model_result.update({'execution_time': result.execution_time}) %}
        {% do model_result.update({'rows_affected': result.adapter_response.get('rows_affected', '') }) %}
        {% do model_result.update({'query_id': result.adapter_response.get('query_id', '') }) %}
        {% do model_result.update({'thread_id': result.thread_id}) %}
        {% do model_result.update({'tags': result.node.tags}) %}
        {% do model_result.update({'failures': result.failures or ''}) %}
        {% do model_result.update({'invocation_id': invocation_id}) %}

        {% for timing in result.timing %}
            {% if timing['name'] == 'execute' %}
                {% set timing_result={} %}
                {% do timing_result.update({'started_at': timing['started_at'].strftime("%Y-%m-%d %H:%M:%S:%f") }) %}
                {% do timing_result.update({'completed_at': timing['completed_at'].strftime("%Y-%m-%d %H:%M:%S:%f") }) %}
                {% do model_result.update({'timing': timing_result}) %}
            {% endif %}
        {% endfor %}

        {% do run_results.append(model_result) %}

    {% endif %}

{% endfor %}

{% do run_audit.update({'run_results': run_results}) %}

-- add the target to the run audit
{% set run_target={} %}

{% for key in cc_dbt_utils.get_target_keys() %}
    {% do run_target.update({key: target[key]}) %}
{% endfor %}

{% do run_audit.update({'target': run_target}) %}

-- add the run flags to the run audit
{% set run_flags={} %}

{% do run_flags.update({'full_refresh': flags.FULL_REFRESH}) %}

{% do run_audit.update({'flags': run_flags}) %}

{#- Escape quotes -#}
{{ return(run_audit | replace("'", "''")) }}


select 1;
{% endmacro %}

{% macro get_target_keys() %}
    {{ return(adapter.dispatch('get_target_keys', 'cc_dbt_utils')()) }}
{% endmacro %}

{% macro default__get_target_keys() %}
{# Abstracting this into a macro so people can override it in their own projects #}
    {{ return([
        'name',
        'user',
        'database',
        'schema'
    ]) }}
{% endmacro %}
