using AlgebraicRelations.ACSetDB
using AlgebraicRelations.ACSetQueries
using SQLite
using DataFrames

@present WorkplaceSchema <: TheorySQL begin
  # Data tables
  employees::Ob
  employees_1_person::Attr(employees, Int64)
  employees_2_id::Attr(employees, Int64)

  names::Ob
  names_1_person::Hom(names, employees)
  names_2_full_name::Attr(names, String)

  salary::Ob
  salary_1_person::Hom(salary, employees)
  salary_2_salary::Attr(salary, Float64)

  # Relation tables
  manager::Ob
  manager_1_person::Hom(manager, employees)
  manager_2_manager::Hom(manager, employees)

  relation::Ob
  relation_1_person1::Hom(relation, employees)
  relation_2_person2::Hom(relation, employees)
  relation_3_relationship::Attr(relation, Float64)
end;

Workplace = SchemaType(WorkplaceSchema)
schema = Workplace()

db = SQLite.DB()
splt_stmts = split(generate_schema_sql(schema), "\n")

@testset "Generate DB Schema" begin
  for stmt in splt_stmts
    @test DBInterface.execute(db, stmt) isa SQLite.Query
  end
end

# Fill out the table
insert_stmts = ["INSERT INTO employees    VALUES (1, 1);",
                "INSERT INTO employees    VALUES (2, 2);",
                "INSERT INTO employees    VALUES (3, 3);",
                "INSERT INTO employees    VALUES (4, 4);",
                "INSERT INTO names        VALUES (1, 'Alice Smith');",
                "INSERT INTO names        VALUES (2, 'Bob Jones');",
                "INSERT INTO names        VALUES (3, 'Eve Johnson');",
                "INSERT INTO names        VALUES (4, 'John Doe');",
                "INSERT INTO manager      VALUES (1, 1);",
                "INSERT INTO manager      VALUES (2, 1);",
                "INSERT INTO manager      VALUES (3, 4);",
                "INSERT INTO manager      VALUES (4, 1);",
                "INSERT INTO salary       VALUES (1, 150000);",
                "INSERT INTO salary       VALUES (2, 50000);",
                "INSERT INTO salary       VALUES (3, 80000);",
                "INSERT INTO salary       VALUES (4, 90000);"]

for stmt in insert_stmts
  DBInterface.execute(db, stmt)
end


@testset "Generate SQL Queries" begin
  q = @query schema (p, n) where (p::Int64, n::String, m::Int64, m1::Int64) begin
    manager(p,m)
    manager(m, m1)
    manager(m1, m)
    names(p, n)
  end

  A = DBInterface.execute(db, to_sql(q)) |> DataFrame
  @test A isa DataFrame
  @test ["Alice Smith",
         "Bob Jones",
         "John Doe"] == A[!, "n"]
end
