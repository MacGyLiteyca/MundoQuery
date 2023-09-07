[
Tablas_Base = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each [Extension] = ".xlsx"),
    Filtered_Folder = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\VersionesBI\V12 Mac\")),
    Filtered_Name = Table.SelectRows(Filtered_Folder, each Text.StartsWith([Name], "Tablas Base")),
    Removed_Other_Columns = Table.SelectColumns(Filtered_Name,{"Content"}),
    Transform_Content = Table.TransformColumns(Removed_Other_Columns, {"Content", each Excel.Workbook(_)}),
    Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data", "Item", "Kind", "Hidden"}, {"Name", "Data", "Item", "Kind", "Hidden"}),
    Filtered_Kind_Table = Table.SelectRows(Expanded_Content, each [Kind] = "Table")
in
    Filtered_Kind_Table
]