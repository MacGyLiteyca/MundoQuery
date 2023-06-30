let
    generateBinaryTree = let
    generateBinaryTree = (text as text) as record =>
    let
        buildTree = (input as text, tree as record) as record =>
        let
            character = Text.Start(input, 1),
            remainingText = Text.AfterDelimiter(input, 1),
            newNode = [Value = character, left = null, right = null],
            newTree = Record.AddField(tree, character, newNode),
            updatedTree = if remainingText <> "" then @buildTree(remainingText, newTree) else newTree
        in
            updatedTree,

        createBinaryTree = (inputText as text) as record =>
        let
            rootNode = [Value = null, left = null, right = null],
            binaryTree = buildTree(inputText, rootNode)
        in
            binaryTree,

        convertUsingBinaryTree = (inputText as text, binaryTree as record) as text =>
        let
            convertCharacter = (character as text, currentNode as record) as text =>
            let
                currentValue = currentNode[Value],
                leftChild = Record.Field(currentNode, character & "left"),
                rightChild = Record.Field(currentNode, character & "right"),
                convertedCharacter = if character = currentValue then character else "",
                convertedLeftChild = if leftChild <> null then @convertCharacter(character, leftChild) else "",
                convertedRightChild = if rightChild <> null then @convertCharacter(character, rightChild) else ""
            in
                convertedCharacter & convertedLeftChild & convertedRightChild,

            convertedText = List.Accumulate(Text.ToList(inputText), "", (state, currentCharacter) => state & convertCharacter(currentCharacter, binaryTree))
        in
            convertedText
    in
        [
            BinaryTree = createBinaryTree(text),
            ConvertedText = convertUsingBinaryTree(text, createBinaryTree(text))
        ]
in
    generateBinaryTree
in
    generateBinaryTree