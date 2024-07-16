//FX_Fecha_Inicial_X_Meses
(Meses as number) as date =>
let
    Factorial = (Meses as number, optional Fecha as date) =>
        let
            Calculo_Fecha = if(Fecha=null)then(Date.StartOfMonth(Date.From(DateTime.FixedLocalNow())))else(Date.StartOfMonth(Date.AddDays(Fecha, -1))),
            Check = if(Meses = 0)then(Calculo_Fecha)else(@Factorial(Meses-1, Calculo_Fecha))
        in Check,
    Calculo = Factorial(Meses)
in
    Calculo