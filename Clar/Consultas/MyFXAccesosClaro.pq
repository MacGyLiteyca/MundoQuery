// MyFXAccesosClaro
let
    Source = (CC as nullable text, CCGestor as nullable text, CCSuper as nullable text, CCLider as nullable text, CCProfesional as nullable text, CCContratista as nullable text, CargoContratista as nullable text, Fecha as nullable date) as table => let
        MyFx = (MyCC as any, MyAcceso as any, MyCargo as any, MyFecha as any)=> let
            MyMes = Number.From(Date.Month(MyFecha)),
            MyAño = Number.From(Date.Year(MyFecha)),
            Origen = Record.AddField(Record.AddField(Record.AddField(Record.AddField(Record.AddField(Record.AddField([], 
                "CCTec", MyCC), 
                "Acceso", MyAcceso), 
                "Cargo", MyCargo), 
                "Año", MyAño),
                "Mes", MyMes),
                "Fecha", MyFecha)
            in Origen, 
        AddedCustom = 
            Table.FromRecords(
                {
                    MyFx(CC, "Admin", "Admin", Fecha),
                    MyFx(CC, CC, "Tecnico", Fecha),
                    MyFx(CC, CCGestor, "Gestor", Fecha),
                    MyFx(CC, CCSuper, "Supervisor", Fecha),
                    MyFx(CC, CCContratista, CargoContratista, Fecha),
                    MyFx(CC, CCLider, "Lider", Fecha),
                    MyFx(CC, CCProfesional, "Profesional", Fecha)
                }),
        CambiarTipos = Table.TransformColumnTypes(AddedCustom,{{"CCTec", type text}, {"Acceso", type text}, {"Cargo", type text}, {"Año", Int64.Type}, {"Mes", Int64.Type}, {"Fecha", type date}}),
        QuitarErrores = Table.RemoveRowsWithErrors(CambiarTipos, {"CCTec", "Acceso", "Cargo", "Año", "Mes", "Fecha"}),
        QuitarNull = Table.SelectRows(QuitarErrores, each [Acceso] <> null and [Acceso] <> "")
    in
        QuitarNull
in
    Source