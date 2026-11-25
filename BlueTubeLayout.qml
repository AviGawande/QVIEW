// TubeDiagramDemo.qml
// Standalone demo: tube + pipes, valves, arrows, dots and labels from the sketch.
// Requires Qt 5.15+ (inline components) - works on Qt 6 too.
//
// Run with:   qml TubeDiagramDemo.qml        (Qt 6)
//             qmlscene TubeDiagramDemo.qml   (Qt 5.15)
// or paste into the main.qml of a new Qt Quick Application.

import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: win
    visible: true
    width: 400
    height: 400
    color: "#1e1e1e"
    title: "Tube Diagram"

    // ===============================================================
    // SMALL BUILDING BLOCKS
    // ===============================================================

    // ---- Tag: label text -------------------------------------------
    component Tag: Text {
        property real u: 1
        color: "#cfd8dc"
        font.pixelSize: 10 * u
        font.bold: true
    }

    // ---- Pipe: axis-aligned line between two points ----------------
    component Pipe: Rectangle {
        id: pipe
        property real u: 1
        property real x1: 0
        property real y1: 0
        property real x2: 0
        property real y2: 0
        property real thickness: 2
        readonly property bool horizontal: y1 === y2
        readonly property real t: thickness * u

        color: "#8fa3b8"
        x: (horizontal ? Math.min(x1, x2) : x1) * u - t / 2
        y: (horizontal ? y1 : Math.min(y1, y2)) * u - t / 2
        width: horizontal ? Math.abs(x2 - x1) * u + t : t
        height: horizontal ? t : Math.abs(y2 - y1) * u + t
    }

    // ---- Valve: two triangles touching at the tip ------------------
    component Valve: Item {
        id: valve
        property real u: 1
        property real cx: 0
        property real cy: 0
        property real span: 18
        property real girth: 12
        property string orientation: "vertical"   // vertical | horizontal
        property color color: "#e3eaf0"
        property string label: ""
        property string labelSide: "right"        // left | right | top | bottom
        readonly property bool vert: orientation === "vertical"

        width: (vert ? girth : span) * u
        height: (vert ? span : girth) * u
        x: cx * u - width / 2
        y: cy * u - height / 2

        onColorChanged: shape.requestPaint()
        onVertChanged: shape.requestPaint()

        Canvas {
            id: shape
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = valve.color
                var w = width
                var h = height
                ctx.beginPath()
                if (valve.vert) {
                    ctx.moveTo(0, 0); ctx.lineTo(w, 0); ctx.lineTo(w / 2, h / 2); ctx.closePath()
                    ctx.moveTo(0, h); ctx.lineTo(w, h); ctx.lineTo(w / 2, h / 2); ctx.closePath()
                } else {
                    ctx.moveTo(0, 0); ctx.lineTo(0, h); ctx.lineTo(w / 2, h / 2); ctx.closePath()
                    ctx.moveTo(w, 0); ctx.lineTo(w, h); ctx.lineTo(w / 2, h / 2); ctx.closePath()
                }
                ctx.fill()
            }
        }

        Tag {
            u: valve.u
            text: valve.label
            visible: text !== ""
            x: valve.labelSide === "right" ? valve.width + 3 * u
             : valve.labelSide === "left"  ? -width - 3 * u
             : (valve.width - width) / 2
            y: valve.labelSide === "top"    ? -height - 1 * u
             : valve.labelSide === "bottom" ? valve.height + 1 * u
             : (valve.height - height) / 2
        }
    }

    // ---- FlowArrow: stem + triangular head -------------------------
    component FlowArrow: Item {
        id: arrow
        property real u: 1
        property real cx: 0
        property real y0: 0
        property real length: 30
        property string direction: "down"         // down | up
        property color color: "#4fc3f7"
        property string label: ""
        property string labelSide: "left"         // left | right
        readonly property bool down: direction === "down"
        readonly property real headH: 9 * u
        readonly property real headW: 10 * u

        x: cx * u - headW / 2
        y: y0 * u
        width: headW
        height: length * u

        onColorChanged: head.requestPaint()
        onDownChanged: head.requestPaint()

        Rectangle {
            width: 2 * arrow.u
            x: (arrow.width - width) / 2
            y: arrow.down ? 0 : arrow.headH
            height: arrow.height - arrow.headH
            color: arrow.color
        }

        Canvas {
            id: head
            width: arrow.headW
            height: arrow.headH
            y: arrow.down ? arrow.height - arrow.headH : 0
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = arrow.color
                ctx.beginPath()
                if (arrow.down) {
                    ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width / 2, height)
                } else {
                    ctx.moveTo(0, height); ctx.lineTo(width, height); ctx.lineTo(width / 2, 0)
                }
                ctx.closePath()
                ctx.fill()
            }
        }

        Tag {
            u: arrow.u
            text: arrow.label
            visible: text !== ""
            x: arrow.labelSide === "right" ? arrow.width + 3 * u : -width - 3 * u
            y: (arrow.height - height) / 2
        }
    }

    // ---- Dot: filled connection point ------------------------------
    component Dot: Rectangle {
        id: dot
        property real u: 1
        property real cx: 0
        property real cy: 0
        property real diameter: 9
        property string label: ""
        property string labelSide: "left"         // left | right | top | bottom

        width: diameter * u
        height: width
        radius: width / 2
        color: "#e3eaf0"
        x: cx * u - width / 2
        y: cy * u - height / 2

        Tag {
            u: dot.u
            text: dot.label
            visible: text !== ""
            x: dot.labelSide === "right" ? dot.width + 3 * u
             : dot.labelSide === "left"  ? -width - 3 * u
             : (dot.width - width) / 2
            y: dot.labelSide === "top"    ? -height - 1 * u
             : dot.labelSide === "bottom" ? dot.height + 1 * u
             : (dot.height - height) / 2
        }
    }

    // ===============================================================
    // THE TUBE DIAGRAM  (design space 420 x 304, scales with width)
    // ===============================================================
    component TubeDiagram: Item {
        id: diagram

        property string status: ""
        property color pipeColor: "#8fa3b8"
        property color flowColor: "#4fc3f7"
        property color valveColor: "#e3eaf0"

        readonly property real designW: 420
        readonly property real designH: 304
        readonly property real u: width / designW

        implicitHeight: designH * u

        // background
        Rectangle {
            anchors.fill: parent
            radius: 6
            color: "#3a3a3a"
            border.color: "#505050"
        }

        // ---------------- PIPES ----------------
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 150; y1: 70;  x2: 360; y2: 70 }   // header
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 172; y1: 70;  x2: 172; y2: 96 }   // header -> tube
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 196; y1: 46;  x2: 196; y2: 70 }   // AGG stem

        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 360; y1: 70;  x2: 360; y2: 232 }  // right vertical
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 360; y1: 150; x2: 388; y2: 150 }  // mPV stub

        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 30;  y1: 214; x2: 244; y2: 214 }  // bottom pipe
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 30;  y1: 214; x2: 30;  y2: 232 }  // left drop
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 50;  y1: 146; x2: 50;  y2: 214 }  // mTV stem
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 244; y1: 146; x2: 244; y2: 214 }  // ADV stem

        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 284; y1: 90;  x2: 306; y2: 90 }   // CR/TR bracket
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 306; y1: 90;  x2: 306; y2: 122 }  // CR
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 306; y1: 134; x2: 306; y2: 180 }  // TR
        Pipe { u: diagram.u; color: diagram.pipeColor; x1: 306; y1: 180; x2: 282; y2: 180 }  // to ADV

        // ---------------- TUBE ----------------
        Rectangle {
            x: 36 * diagram.u
            y: 96 * diagram.u
            width: 240 * diagram.u
            height: 50 * diagram.u
            border.color: "#b0bec5"
            border.width: Math.max(1, 1.5 * diagram.u)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#78909c" }
                GradientStop { position: 0.5; color: "#cfd8dc" }
                GradientStop { position: 1.0; color: "#607d8b" }
            }
        }
        // flanges
        Rectangle {
            x: 28 * diagram.u; y: 88 * diagram.u
            width: 8 * diagram.u; height: 66 * diagram.u
            color: "#546e7a"; border.color: "#b0bec5"
        }
        Rectangle {
            x: 276 * diagram.u; y: 88 * diagram.u
            width: 8 * diagram.u; height: 66 * diagram.u
            color: "#546e7a"; border.color: "#b0bec5"
        }
        // domes
        Rectangle {
            x: 36 * diagram.u; y: 100 * diagram.u
            width: 16 * diagram.u; height: 42 * diagram.u
            radius: 8 * diagram.u
            color: "#455a64"
        }
        Rectangle {
            x: 260 * diagram.u; y: 100 * diagram.u
            width: 16 * diagram.u; height: 42 * diagram.u
            radius: 8 * diagram.u
            color: "#455a64"
        }

        // status text inside the tube
        Tag {
            u: diagram.u
            text: diagram.status
            color: "#102027"
            font.pixelSize: 11 * diagram.u
            x: 156 * diagram.u - width / 2
            y: 121 * diagram.u - height / 2
        }

        // GSM marker
        Rectangle {
            x: 111 * diagram.u; y: 88 * diagram.u
            width: 3 * diagram.u; height: 16 * diagram.u
            color: diagram.valveColor
        }
        Tag { u: diagram.u; text: "GSM"; x: 80 * diagram.u; y: 90 * diagram.u }

        // ---------------- BASE ----------------
        Rectangle {
            x: 30 * diagram.u; y: 232 * diagram.u
            width: 362 * diagram.u; height: 48 * diagram.u
            color: "transparent"
            border.color: diagram.pipeColor
            border.width: Math.max(1, 1.5 * diagram.u)
        }

        Canvas {
            x: 30 * diagram.u; y: 232 * diagram.u
            width: 362 * diagram.u; height: 18 * diagram.u
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = diagram.pipeColor
                ctx.lineWidth = Math.max(1, diagram.u)
                ctx.beginPath()
                var step = 8 * diagram.u
                for (var i = -height; i < width; i += step) {
                    ctx.moveTo(i, height)
                    ctx.lineTo(i + height, 0)
                }
                ctx.stroke()
            }
        }

        Pipe { u: diagram.u; color: diagram.pipeColor; thickness: 1.5; x1: 30;  y1: 250; x2: 392; y2: 250 }
        Pipe { u: diagram.u; color: diagram.pipeColor; thickness: 1.5; x1: 360; y1: 250; x2: 360; y2: 280 }

        Tag { u: diagram.u; text: "Beach Body"; x: 36 * diagram.u;  y: 216 * diagram.u }
        Tag { u: diagram.u; text: "NO FUND";    x: 190 * diagram.u; y: 216 * diagram.u }
        Tag { u: diagram.u; text: "TOM";        x: 215 * diagram.u; y: 258 * diagram.u }

        // ---------------- ARROWS ----------------
        FlowArrow { u: diagram.u; color: diagram.flowColor; cx: 54;  y0: 6;   length: 32; direction: "down"; label: "SVV" }
        FlowArrow { u: diagram.u; color: diagram.flowColor; cx: 54;  y0: 44;  length: 52; direction: "up";   label: "MTS" }

        FlowArrow { u: diagram.u; color: diagram.flowColor; cx: 150; y0: 6;   length: 32; direction: "down"; label: "PE" }
        FlowArrow { u: diagram.u; color: diagram.flowColor; cx: 150; y0: 44;  length: 26; direction: "up" }

        FlowArrow { u: diagram.u; color: diagram.flowColor; cx: 196; y0: 6;   length: 26; direction: "down" }

        FlowArrow { u: diagram.u; color: diagram.flowColor; cx: 150; y0: 268; length: 34; direction: "down" }
        FlowArrow { u: diagram.u; color: diagram.flowColor; cx: 360; y0: 256; length: 24; direction: "down" }

        // ---------------- VALVES ----------------
        Valve { u: diagram.u; color: diagram.valveColor; cx: 196; cy: 46;  label: "AGG"; labelSide: "right" }
        Valve { u: diagram.u; color: diagram.valveColor; cx: 252; cy: 70;  label: "KV";  labelSide: "top" }

        Valve { u: diagram.u; color: diagram.valveColor; cx: 50;  cy: 180; label: "mTV"; labelSide: "left" }
        Valve { u: diagram.u; color: diagram.valveColor; cx: 244; cy: 180; label: "ADV"; labelSide: "right" }

        Valve { u: diagram.u; color: diagram.valveColor; cx: 394; cy: 150; label: "mPV"; labelSide: "top" }
        Valve { u: diagram.u; color: diagram.valveColor; cx: 360; cy: 205; label: "BK";  labelSide: "right" }

        Valve { u: diagram.u; color: diagram.valveColor; cx: 150; cy: 243; span: 22 }

        // ---------------- DOTS ----------------
        Dot { u: diagram.u; cx: 222; cy: 180; label: "GN"; labelSide: "left" }
        Dot { u: diagram.u; cx: 394; cy: 96;  label: "PE"; labelSide: "top" }

        // ---------------- OTHER LABELS ----------------
        Tag { u: diagram.u; text: "CR";  x: 312 * diagram.u; y: 96 * diagram.u }
        Tag { u: diagram.u; text: "TR";  x: 312 * diagram.u; y: 148 * diagram.u }
        Tag { u: diagram.u; text: "TAN"; x: 384 * diagram.u; y: 162 * diagram.u }
    }

    // ===============================================================
    // DEMO CONTENT
    // ===============================================================
    TubeDiagram {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 15
        width: parent.width - 30
        status: "FILLING_IN_PROGRESS"
    }
}
