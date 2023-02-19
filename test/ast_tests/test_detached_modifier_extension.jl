Node = Norg.AST.Node
AST = Norg.AST

detached_modifier = ["-", "~", ">", "*"]

todos = [
    (" ", K"StatusUndone")
    ("x", K"StatusDone")
    ("?", K"StatusNeedFurtherInput")
    ("!", K"StatusUrgent")
    ("+", K"StatusRecurring")
    ("-", K"StatusInProgress")
    ("=", K"StatusOnHold")
    ("_", K"StatusCancelled")
]

@testset "Extension on detached modifier '$m'." for m in detached_modifier 
    @testset "Level" for n in 1:7
        @testset "Simple Todos: ($t)" for (t,res) in todos
            s = "$(repeat(m, n)) ($t) hey"
            ast = norg(s)
            nestable = first(children(ast))
            if m == "*"
                item = nestable
            else
                item = first(children(nestable))
            end
            ext, p = children(item)
            @test kind(first(children(ext))) == res
        end
        @testset "Due time extension" begin
            s = "$(repeat(m, n)) (< Monday) hey"
            ast = norg(s)
            nestable = first(children(ast))
            if m == "*"
                item = nestable
            else
                item = first(children(nestable))
            end
            ext, p = children(item)
            @test kind(ext) == K"DueDateExtension"
        end
        @testset "Start time extension" begin
            s = "$(repeat(m, n)) (> Monday) hey"
            ast = norg(s)
            nestable = first(children(ast))
            if m == "*"
                item = nestable
            else
                item = first(children(nestable))
            end
            ext, p = children(item)
            @test kind(ext) == K"StartDateExtension"
        end
        @testset "Timestamp extension" begin
            s = "$(repeat(m, n)) (@ Monday) hey"
            ast = norg(s)
            nestable = first(children(ast))
            if m == "*"
                item = nestable
            else
                item = first(children(nestable))
            end
            ext, p = children(item)
            @test kind(ext) == K"TimestampExtension"
        end
        @testset "Todos chained with timestamp: ($t)" for (t,res) in todos
            s = "$(repeat(m, n)) ($t|@ Tuesday) hey"
            ast = norg(s)
            nestable = first(children(ast))
            if m == "*"
                item = nestable
            else
                item = first(children(nestable))
            end
            ext, p = children(item)
            @test kind(first(children(ext))) == res
            ts_ext = last(children(ext))
            @test kind(ts_ext) == K"TimestampExtension"
        end
        @testset "Todos chained with due date: ($t)" for (t,res) in todos
            s = "$(repeat(m, n)) ($t|< Tuesday) hey"
            ast = norg(s)
            nestable = first(children(ast))
            if m == "*"
                item = nestable
            else
                item = first(children(nestable))
            end
            ext, p = children(item)
            @test kind(first(children(ext))) == res
            ts_ext = last(children(ext))
            @test kind(ts_ext) == K"DueDateExtension"
        end
        @testset "Todos chained with start date: ($t)" for (t,res) in todos
            s = "$(repeat(m, n)) ($t|> Tuesday) hey"
            ast = norg(s)
            nestable = first(children(ast))
            if m == "*"
                item = nestable
            else
                item = first(children(nestable))
            end
            ext, p = children(item)
            @test kind(first(children(ext))) == res
            ts_ext = last(children(ext))
            @test kind(ts_ext) == K"StartDateExtension"
        end
        @testset "Todos chained with priority: ($t)" for (t,res) in todos
            s = "$(repeat(m, n)) ($t|# A) hey"
            ast = norg(s)
            nestable = first(children(ast))
            if m == "*"
                item = nestable
            else
                item = first(children(nestable))
            end
            ext, p = children(item)
            @test kind(first(children(ext))) == res
            ts_ext = last(children(ext))
            @test kind(ts_ext) == K"PriorityExtension"
        end
    end
end

