ace.define('ace/mode/slaw', function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");

var SlawHighlightRules = function() {
    // regexp must not have capturing parentheses
    // regexps are ordered -> the first match is used

    this.$rules = {
        "start" : [{
            token : "constant.character.entity",
            regex : /^[0-9.]+/
        }, {
            token : "constant.language",
            regex : /^\([0-9a-zA-Z]+\)/
        }]
    };
};

var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
oop.inherits(SlawHighlightRules, TextHighlightRules);

var Mode = function() {
    this.HighlightRules = SlawHighlightRules;
};

var TextMode = require("./text").Mode;
oop.inherits(Mode, TextMode);

exports.Mode = Mode;
exports.SlawHighlightRules = SlawHighlightRules;

});
