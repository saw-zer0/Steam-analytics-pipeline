import os
from datetime import datetime, timedelta

from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from cosmos import DbtTaskGroup, ExecutionConfig, ProfileConfig, ProjectConfig
from cosmos.profiles import PostgresUserPasswordProfileMapping

from elt.extract import load_csv_in_batches


PROJECT_PATH = "/opt/airflow/steam_dw_pipeline"


with DAG(
	dag_id="steam_pipeline_dag",
	description="Extract Steam game data and build the Steam analytics dbt project",
	start_date=datetime(2026, 1, 1),
	schedule="@daily",
	catchup=False,
	max_active_runs=1,
	tags=["extract", "dbt", "steam"],
) as dag:
	extract_games = PythonOperator(
		task_id="extract_games",
		python_callable=load_csv_in_batches,
		execution_timeout=timedelta(hours=2),
	)

	build_steam_dw = DbtTaskGroup(
		group_id="build_steam_dw",
		project_config=ProjectConfig(dbt_project_path=PROJECT_PATH),
		profile_config=ProfileConfig(
			profile_name="steam_dw_pipeline",
			target_name="dev",
			profile_mapping=PostgresUserPasswordProfileMapping(
				conn_id="steam_dw",
				profile_args={
					"host": os.getenv("STEAM_DBT_HOST", "host.docker.internal"),
					"schema": "dbt",
				},
			),
		),
		execution_config=ExecutionConfig(dbt_executable_path="dbt"),
		operator_args={"install_deps": False},
	)

	extract_games >> build_steam_dw