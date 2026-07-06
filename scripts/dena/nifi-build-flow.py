#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, asdict


@dataclass(frozen=True)
class ControllerService:
    name: str
    type: str
    properties: dict[str, str]


@dataclass(frozen=True)
class Processor:
    name: str
    type: str
    position: dict[str, float]
    properties: dict[str, str]
    auto_terminated_relationships: list[str]
    scheduling_period: str | None = None


@dataclass(frozen=True)
class Connection:
    source: str
    destination: str
    relationship: str


def build_flow(args: argparse.Namespace) -> dict:
    services = [
        ControllerService(
            name="Verticales DBCP",
            type="org.apache.nifi.dbcp.DBCPConnectionPool",
            properties={
                "Database Connection URL": f"jdbc:postgresql://{args.source_host}:{args.source_port}/{args.source_db}",
                "Database Driver Class Name": "org.postgresql.Driver",
                "Database Driver Locations": args.jdbc_jar,
                "Database User": args.source_user,
                "Password": args.source_password,
            },
        ),
        ControllerService(
            name="Datalake DBCP",
            type="org.apache.nifi.dbcp.DBCPConnectionPool",
            properties={
                "Database Connection URL": f"jdbc:postgresql://{args.target_host}:{args.target_port}/{args.target_db}",
                "Database Driver Class Name": "org.postgresql.Driver",
                "Database Driver Locations": args.jdbc_jar,
                "Database User": args.target_user,
                "Password": args.target_password,
            },
        ),
        ControllerService(
            name="JSON Record Writer",
            type="org.apache.nifi.json.JsonRecordSetWriter",
            properties={},
        ),
        ControllerService(
            name="JSON Record Reader",
            type="org.apache.nifi.json.JsonTreeReader",
            properties={},
        ),
    ]

    processors = [
        Processor(
            name="Query Verticales Incremental",
            type="org.apache.nifi.processors.standard.QueryDatabaseTableRecord",
            position={"x": 160.0, "y": 220.0},
            properties={
                "Database Connection Pooling Service": "Verticales DBCP",
                "Table Name": f"{args.source_schema}.{args.source_table}",
                "Maximum-value Columns": "updated_at,id",
                "Record Writer": "JSON Record Writer",
            },
            auto_terminated_relationships=["failure", "retry"],
            scheduling_period="30 sec",
        ),
        Processor(
            name="Persist Staging Batch",
            type="org.apache.nifi.processors.standard.PutDatabaseRecord",
            position={"x": 480.0, "y": 220.0},
            properties={
                "Database Connection Pooling Service": "Datalake DBCP",
                "Table Name": f"{args.staging_schema}.{args.staging_table}",
                "Unmatched Column Behavior": "Ignore Unmatched Columns",
                "Translate Field Names": "false",
                "Statement Type": "INSERT",
                "Record Reader": "JSON Record Reader",
            },
            auto_terminated_relationships=["failure", "retry"],
        ),
        Processor(
            name="Promote Staging To Main",
            type="org.apache.nifi.processors.standard.ExecuteSQL",
            position={"x": 820.0, "y": 220.0},
            properties={
                "Database Connection Pooling Service": "Datalake DBCP",
                "SQL select query": "SELECT dena.dena_staging_to_main();",
            },
            auto_terminated_relationships=["success", "failure"],
        ),
    ]

    connections = [
        Connection(
            source="Query Verticales Incremental",
            destination="Persist Staging Batch",
            relationship="success",
        ),
        Connection(
            source="Persist Staging Batch",
            destination="Promote Staging To Main",
            relationship="success",
        ),
    ]

    return {
        "group_name": args.group_name,
        "source": {
            "schema": args.source_schema,
            "table": args.source_table,
            "incremental_columns": ["updated_at", "id"],
        },
        "staging": {
            "schema": args.staging_schema,
            "table": args.staging_table,
            "merge_function": "dena.dena_staging_to_main",
        },
        "services": [asdict(service) for service in services],
        "processors": [
            {
                **asdict(processor),
                "auto_terminated_relationships": processor.auto_terminated_relationships,
            }
            for processor in processors
        ],
        "connections": [asdict(connection) for connection in connections],
        "ui_notes": [
            "Crear o reutilizar el grupo de proceso.",
            "Crear dos controller services DBCP, el JSON Record Writer y el JSON Record Reader.",
            "Crear QueryDatabaseTableRecord, PutDatabaseRecord y ExecuteSQL.",
            "Conectar success de Query -> PutDatabaseRecord y PutDatabaseRecord -> ExecuteSQL.",
            "Arrancar los controller services antes de arrancar los procesadores.",
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Build the DENA Fase 15 NiFi flow spec.")
    parser.add_argument("--group-name", default="Fase 15 - DENA staging incremental")
    parser.add_argument("--source-schema", default="expedientes")
    parser.add_argument("--source-table", default="admin_file")
    parser.add_argument("--source-host", default="postgresql-verticales.verticales.svc.cluster.local")
    parser.add_argument("--source-port", default="5432")
    parser.add_argument("--source-db", default="expedientes")
    parser.add_argument("--source-user", default="postgres")
    parser.add_argument("--source-password", default="REPLACE_ME")
    parser.add_argument("--target-host", default="postgresql-datalake.datalake.svc.cluster.local")
    parser.add_argument("--target-port", default="5432")
    parser.add_argument("--target-db", default="datalake")
    parser.add_argument("--target-user", default="postgres")
    parser.add_argument("--target-password", default="REPLACE_ME")
    parser.add_argument("--staging-schema", default="dena")
    parser.add_argument("--staging-table", default="admin_file_staging")
    parser.add_argument("--jdbc-jar", default="/opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar")
    parser.add_argument("--format", choices=("json", "markdown"), default="json")
    args = parser.parse_args()

    flow = build_flow(args)

    if args.format == "markdown":
        print(f"# {flow['group_name']}")
        print()
        print("## Source")
        print(f"- {flow['source']['schema']}.{flow['source']['table']}")
        print("- Incremental columns: updated_at, id")
        print()
        print("## Staging")
        print(f"- {flow['staging']['schema']}.{flow['staging']['table']}")
        print(f"- Merge function: {flow['staging']['merge_function']}")
        print()
        print("## Services")
        for service in flow["services"]:
            print(f"- {service['name']} ({service['type']})")
        print()
        print("## Processors")
        for processor in flow["processors"]:
            schedule = processor.get("scheduling_period")
            if schedule:
                print(f"- {processor['name']} ({processor['type']}) every {schedule}")
            else:
                print(f"- {processor['name']} ({processor['type']})")
        print()
        print("## Connections")
        for connection in flow["connections"]:
            print(
                f"- {connection['source']} -> {connection['destination']} "
                f"({connection['relationship']})"
            )
        return

    print(json.dumps(flow, indent=2, ensure_ascii=True))


if __name__ == "__main__":
    main()
