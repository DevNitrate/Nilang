import strutils, sequtils, re

proc error*(msg: string, line: int) =
    echo "Error on line ", line, ": ", msg
    system.quit(1)

proc lexer*(content: string): seq[seq[tuple[tokenType: string, token: string]]] =
    var lines: seq[string] = content.split("\n")
    var lineCount: int = 0
    var lineTokens: seq[seq[tuple[tokenType: string, token: string]]]

    for line in lines:
        lineCount += 1
        let chars: seq[char] = toSeq(line.items)

        var tokens: seq[string] = @[]
        var tempStr = ""
        var quoteCount: int = 0
        var inQuotes: bool = false

        for c in chars:
            if c == '"':
                quoteCount += 1
            if quoteCount mod 2 == 0:
                inQuotes = false
            else:
                inQuotes = true
            if c == ' ' and inQuotes == false:
                tokens.add(tempStr)
                tempStr = ""
            else:
                tempStr.add(c)
        tokens.add(tempStr)

        var items: seq[tuple[tokenType: string, token: string]]
        
        for token in tokens:
            var quotes: bool = false

            if token[0] == '"':
                quotes = true
                var index: int = len(token) - 2
                if token[index] == '"':
                    let removeLast = token[0.. ^2]
                    let value: tuple[tokenType: string, token: string] = ("string", removeLast)
                    items.add(value)
                elif token[^1] == '"':
                    let value: tuple[tokenType: string, token: string] = ("string", token)
                    items.add(value)
                elif token[^1] == '\n':
                    if token[index] != '"':
                        error("unclosed quotes", lineCount)
                else:
                    error("unclosed quotes", lineCount)
            elif match(token, re"[.a-zA-Z]+"):
                let value: tuple[tokenType: string, token: string] = ("symbol", token.replace("\r", ""))
                items.add(value)
            elif token in "+-*/":
                let value: tuple[tokenType: string, token: string] = ("expression", token.replace("\r", ""))
                items.add(value)
            elif contains(token, re"[.0-9]+"):
                let value: tuple[tokenType: string, token: string] = ("number", token.replace("\r", ""))
                items.add(value)
        lineTokens.add(items)
        
    return lineTokens

var symbols = @["var", "print"]
var vars: seq[tuple[name: string, value: string]]

proc parse*(file: string) =
    let content: string = readFile(file)
    if content == "":
        error(file & " is empty", 1)

    var lines: seq[seq[tuple[tokenType: string, token: string]]] = lexer(content)

    for i, line in lines:
        for t, token in line:
            if token[0] == "symbol":
                if token[1] in symbols:
                    if token[1] == "print":
                        if line.len > 1:
                            if line[2].tokenType == "expression":
                                var x: float = parseFloat(line[1].token)
                                var y: float = parseFloat(line[3].token)

                                if line[2].token == "+":
                                    let value = x + y
                                    echo value
                                elif line[2].token == "-":
                                    let value = x - y
                                    echo value
                                elif line[2].token == "*":
                                    let value = x * y
                                    echo value
                                elif line[2].token == "/":
                                    let value = x / y
                                    echo value
                        else:
                            if line[t+1].tokenType == "string":
                                var value: string = (line[i+1].token)[0.. ^2]
                                value = value[1.. ^1]
                                echo value
                            elif line[t+1].tokenType == "symbol":
                                var varExists: bool = false
                                var varIndex: int = 0
                                for k, v in vars:
                                    if v.name == line[t+1].token:
                                        varExists = true
                                        varIndex = k
                                
                                if varExists == true:
                                    echo vars[varIndex].value
                            else:
                                echo line[t+1].token
                        break
                    elif token.token == "var":
                        if contains(line[i+1].token, re"[.a-zA-Z0-9_]+"):
                            if line.len > 3:
                                if line[3].tokenType == "expression":
                                    var x: float = parseFloat(line[2].token)
                                    var y: float = parseFloat(line[4].token)

                                    if line[3].token == "+":
                                        let value = x + y
                                        let variable: tuple[name: string, value: string] = (line[1].token, $value)
                                        vars.add(variable)
                                    elif line[3].token == "-":
                                        let value = x - y
                                        let variable: tuple[name: string, value: string] = (line[1].token, $value)
                                        vars.add(variable)
                                    elif line[3].token == "*":
                                        let value = x * y
                                        let variable: tuple[name: string, value: string] = (line[1].token, $value)
                                        vars.add(variable)
                                    elif line[3].token == "/":
                                        let value = x / y
                                        let variable: tuple[name: string, value: string] = (line[1].token, $value)
                                        vars.add(variable)
                            else:
                                let variable: tuple[name: string, value: string] = (line[1].token, line[2].token)
                                vars.add(variable)
                        else:
                            error("variable name isn't valid", i+1)
                        break
                else:
                    var varExists: bool = false
                    var varIndex: int = 0
                    var varValue: string = line[1].token

                    for k, v in vars:
                        if v.name == token[1]:
                            varExists = true
                            varIndex = k
                            break
                    if varExists:
                        vars[varIndex].value = varValue