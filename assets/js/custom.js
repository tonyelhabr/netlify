
/* Reference: https://stackoverflow.com/questions/51110878/how-to-highlight-all-r-function-names-with-highlight-js*/
/*More: http://www.questionflow.org/2017/10/20/highlight-the-pipe-highlight-js/*/
console.log('hi there');

hljs.registerLanguage("r", function (e) {
    var r = "([a-zA-Z]|\\.[a-zA-Z.])[a-zA-Z0-9._]*";
    return {
        c: [
            e.HCM,
                
            {
                cN: "pipe",
                b: "%>%",
                r: 0
            },
            // Function parameters with good style as 'variable' + 'space' + '=' + 'space'
            {
                cN: "fun-param",
                b: "([a-zA-Z]|\\.[a-zA-Z.])[a-zA-Z0-9._]*\\s+=\\s+",
                r: 0
            },
            // Assign operator with good style
            {
                cN: "assign",
                b: "<-",
                r: 0
            },
            // Adding to class 'keyword' the explicit use of function's package
            {
                cN: "keyword",
                b: "([a-zA-Z]|\\.[a-zA-Z.])[a-zA-Z0-9._]*::",
                r: 0
            },
            // Class for basic dplyr words with their scoped variants
            {
                cN: "tidyverse",
                b: "as_tibble|tibble|mutate|select|filter|summari[sz]e|arrange|group_by|drop_na|ungroup|distinct|pivot_(wider|longer)|pluck|fill|replace_na|crossing|vctrs|p?map2?|(inner|left|right|full)_join|across|row_number|nest|unnest",
                end: "[a-zA-Z0-9._]*",
                r: 0
            },
            {
                cN: "python",
                b: "flatten|DataFrame|(np|pd)[.]",
                end: "[a-zA-Z0-9._]*",
                r: 0
            },
            //{ cN: "dt", k: { keyword: "data.table" }, r: 0},

            {
                b: r,
                l: r,
                k: {
                    keyword: "function if in break next repeat else for return switch while try tryCatch stop warning require library attach detach source setMethod setGeneric setGroupGeneric setClass ... UseMethod c matrix cat sprintf paste paste0 list print sqrt sum class exp pi",
                    literal: "NULL NA TRUE FALSE T F Inf NaN NA_integer_|10 NA_real_|10 NA_character_|10 NA_complex_|10",
                },
                r: 0,
            },

            {
                cN: "number",
                b: "0[xX][0-9a-fA-F]+[Li]?\\b",
                r: 0
            },
            {
                cN: "number",
                b: "\\d+(?:[eE][+\\-]?\\d*)?L\\b",
                r: 0
            },
            {
                cN: "number",
                b: "\\d+\\.(?!\\d)(?:i\\b)?",
                r: 0
            },
            {
                cN: "number",
                b: "\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d*)?i?\\b",
                r: 0
            },
            {
                cN: "number",
                b: "\\.\\d+(?:[eE][+\\-]?\\d*)?i?\\b",
                r: 0
            },
            {
                b: "`",
                e: "`",
                r: 0
            },
            {
                cN: "string",
                c: [e.BE],
                v: [{
                        b: '"',
                        e: '"'
                    },
                    {
                        b: "'",
                        e: "'"
                    },
                ],
            },
        ],
    };;
});

hljs.initHighlightingOnLoad();

