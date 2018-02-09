<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="FlowChart.aspx.cs" EnableEventValidation="false" Inherits="TestCKEditor.FlowChart" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <script src="../Scripts/go.js/go.js"></script>
    <script src="../Scripts/jquery-3.3.1.min.js"></script>
     <script src="Scripts/go.js/go.js"></script>
    <script src="Scripts/jquery-3.3.1.min.js"></script>
    <title></title>
</head>
<body onload="init()">
    <form runat="server">
        <div id="sample">
            <asp:DropDownList runat="server" ID="dropdownlistHistory"></asp:DropDownList>
            <asp:Button runat="server" ID="buttonLoad" Text="Load" OnClientClick="return LoadData()" />
            <asp:TextBox runat="server" ID="textboxName"></asp:TextBox>
            <asp:Button runat="server" ID="buttonSave" Text="Save" OnClientClick="return SaveData()" OnClick="buttonSave_Click" />
            <asp:Button runat="server" ID="buttonSubmit" Text="Submit" OnClientClick="SubmitClick()" OnClick="button1_Click" />
            <div style="width: 100%; padding-top: 10px; display: flex; justify-content: space-between">
                <div id="myPaletteDiv" style="width: 100px; height: 350px; margin-right: 2px; background-color: whitesmoke; border: solid 1px black"></div>
                <div id="myDiagramDiv" style="flex-grow: 1; height: 350px; border: solid 1px black"></div>
            </div>
            <asp:HiddenField runat="server" ID="hiddenfieldName" />
            <asp:HiddenField runat="server" ID="hiddenfieldData" />
            <asp:HiddenField runat="server" ID="hiddenfieldParam" />
        </div>
    </form>
    <script type="text/javascript">
        var myDiagram;
        var urlParams;
        (window.onpopstate = function () {
            var match,
                pl = /\+/g,  // Regex for replacing addition symbol with a space
                search = /([^&=]+)=?([^&]*)/g,
                decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); },
                query = window.location.search.substring(1);

            urlParams = {};
            while (match = search.exec(query))
                urlParams[decode(match[1])] = decode(match[2]);
        })();
        function init() {
            if (window.goSamples) goSamples();  // init for these samples -- you don't need to call this
            var $ = go.GraphObject.make;  // for conciseness in defining templates

            myDiagram =
              $(go.Diagram, "myDiagramDiv",  // must name or refer to the DIV HTML element
                {
                    initialContentAlignment: go.Spot.Center,
                    allowDrop: true,  // must be true to accept drops from the Palette
                    "LinkDrawn": showLinkLabel,  // this DiagramEvent listener is defined below
                    "LinkRelinked": showLinkLabel,
                    scrollsPageOnFocus: false,
                    "undoManager.isEnabled": true  // enable undo & redo
                });

            // when the document is modified, add a "*" to the title and enable the "Save" button
            myDiagram.addDiagramListener("Modified", function (e) {
                var button = document.getElementById("SaveButton");
                if (button) button.disabled = !myDiagram.isModified;
                var idx = document.title.indexOf("*");
                if (myDiagram.isModified) {
                    if (idx < 0) document.title += "*";
                } else {
                    if (idx >= 0) document.title = document.title.substr(0, idx);
                }
            });

            // helper definitions for node templates

            function nodeStyle() {
                return [
                  // The Node.location comes from the "loc" property of the node data,
                  // converted by the Point.parse static method.
                  // If the Node.location is changed, it updates the "loc" property of the node data,
                  // converting back using the Point.stringify static method.
                  new go.Binding("location", "loc", go.Point.parse).makeTwoWay(go.Point.stringify),
                  {
                      // the Node.location is at the center of each node
                      locationSpot: go.Spot.Center,
                      //isShadowed: true,
                      //shadowColor: "#888",
                      // handle mouse enter/leave events to show/hide the ports
                      mouseEnter: function (e, obj) { showPorts(obj.part, true); },
                      mouseLeave: function (e, obj) { showPorts(obj.part, false); }
                  }
                ];
            }

            // Define a function for creating a "port" that is normally transparent.
            // The "name" is used as the GraphObject.portId, the "spot" is used to control how links connect
            // and where the port is positioned on the node, and the boolean "output" and "input" arguments
            // control whether the user can draw links from or to the port.
            function makePort(name, spot, output, input) {
                // the port is basically just a small circle that has a white stroke when it is made visible
                return $(go.Shape, "Circle",
                         {
                             fill: "transparent",
                             stroke: null,  // this is changed to "white" in the showPorts function
                             desiredSize: new go.Size(8, 8),
                             alignment: spot, alignmentFocus: spot,  // align the port on the main Shape
                             portId: name,  // declare this object to be a "port"
                             fromSpot: spot, toSpot: spot,  // declare where links may connect at this port
                             fromLinkable: output, toLinkable: input,  // declare whether the user may draw links to/from here
                             cursor: "pointer"  // show a different cursor to indicate potential link point
                         });
            }

            // define the Node templates for regular nodes

            var lightText = 'whitesmoke';

            myDiagram.nodeTemplateMap.add("",  // the default category
              $(go.Node, "Spot", nodeStyle(),
                // the main object is a Panel that surrounds a TextBlock with a rectangular Shape
                $(go.Panel, "Auto",
                  $(go.Shape, "Rectangle",
                    { fill: "#00A9C9", stroke: null },
                    new go.Binding("figure", "figure")),
                  $(go.TextBlock,
                    {
                        font: "bold 11pt Helvetica, Arial, sans-serif",
                        stroke: lightText,
                        margin: 8,
                        maxSize: new go.Size(160, NaN),
                        wrap: go.TextBlock.WrapFit,
                        editable: true
                    },
                    new go.Binding("text").makeTwoWay())
                ),
                // four named ports, one on each side:
                makePort("T", go.Spot.Top, false, true),
                makePort("L", go.Spot.Left, true, true),
                makePort("R", go.Spot.Right, true, true),
                makePort("B", go.Spot.Bottom, true, false)
              ));

            myDiagram.nodeTemplateMap.add("Start",
              $(go.Node, "Spot", nodeStyle(),
                $(go.Panel, "Auto",
                  $(go.Shape, "Circle",
                    { minSize: new go.Size(40, 40), fill: "#79C900", stroke: null }),
                  $(go.TextBlock, "Start",
                    { font: "bold 11pt Helvetica, Arial, sans-serif", stroke: lightText },
                    new go.Binding("text"))
                ),
                // three named ports, one on each side except the top, all output only:
                makePort("L", go.Spot.Left, true, false),
                makePort("R", go.Spot.Right, true, false),
                makePort("B", go.Spot.Bottom, true, false)
              ));

            myDiagram.nodeTemplateMap.add("End",
              $(go.Node, "Spot", nodeStyle(),
                $(go.Panel, "Auto",
                  $(go.Shape, "Circle",
                    { minSize: new go.Size(40, 40), fill: "#DC3C00", stroke: null }),
                  $(go.TextBlock, "End",
                    { font: "bold 11pt Helvetica, Arial, sans-serif", stroke: lightText },
                    new go.Binding("text"))
                ),
                // three named ports, one on each side except the bottom, all input only:
                makePort("T", go.Spot.Top, false, true),
                makePort("L", go.Spot.Left, false, true),
                makePort("R", go.Spot.Right, false, true)
              ));

            myDiagram.nodeTemplateMap.add("Comment",
              $(go.Node, "Auto", nodeStyle(),
                $(go.Shape, "File",
                  { fill: "#EFFAB4", stroke: null }),
                $(go.TextBlock,
                  {
                      margin: 5,
                      maxSize: new go.Size(200, NaN),
                      wrap: go.TextBlock.WrapFit,
                      textAlign: "center",
                      editable: true,
                      font: "bold 12pt Helvetica, Arial, sans-serif",
                      stroke: '#454545'
                  },
                  new go.Binding("text").makeTwoWay())
                // no ports, because no links are allowed to connect with a comment
              ));


            // replace the default Link template in the linkTemplateMap
            myDiagram.linkTemplate =
              $(go.Link,  // the whole link panel
                {
                    routing: go.Link.AvoidsNodes,
                    curve: go.Link.JumpOver,
                    corner: 5, toShortLength: 4,
                    relinkableFrom: true,
                    relinkableTo: true,
                    reshapable: true,
                    resegmentable: true,
                    // mouse-overs subtly highlight links:
                    mouseEnter: function (e, link) { link.findObject("HIGHLIGHT").stroke = "rgba(30,144,255,0.2)"; },
                    mouseLeave: function (e, link) { link.findObject("HIGHLIGHT").stroke = "transparent"; }
                },
                new go.Binding("points").makeTwoWay(),
                $(go.Shape,  // the highlight shape, normally transparent
                  { isPanelMain: true, strokeWidth: 8, stroke: "transparent", name: "HIGHLIGHT" }),
                $(go.Shape,  // the link path shape
                  { isPanelMain: true, stroke: "gray", strokeWidth: 2 }),
                $(go.Shape,  // the arrowhead
                  { toArrow: "standard", stroke: null, fill: "gray" }),
                $(go.Panel, "Auto",  // the link label, normally not visible
                  { visible: false, name: "LABEL", segmentIndex: 2, segmentFraction: 0.5 },
                  new go.Binding("visible", "visible").makeTwoWay(),
                  $(go.Shape, "RoundedRectangle",  // the label shape
                    { fill: "#F8F8F8", stroke: null }),
                  $(go.TextBlock, "Yes",  // the label
                    {
                        textAlign: "center",
                        font: "10pt helvetica, arial, sans-serif",
                        stroke: "#333333",
                        editable: true
                    },
                    new go.Binding("text").makeTwoWay())
                )
              );

            // Make link labels visible if coming out of a "conditional" node.
            // This listener is called by the "LinkDrawn" and "LinkRelinked" DiagramEvents.
            function showLinkLabel(e) {
                var label = e.subject.findObject("LABEL");
                if (label !== null) label.visible = (e.subject.fromNode.data.figure === "Diamond");
            }

            // temporary links used by LinkingTool and RelinkingTool are also orthogonal:
            myDiagram.toolManager.linkingTool.temporaryLink.routing = go.Link.Orthogonal;
            myDiagram.toolManager.relinkingTool.temporaryLink.routing = go.Link.Orthogonal;

            // initialize the Palette that is on the left side of the page
            myPalette =
              $(go.Palette, "myPaletteDiv",  // must name or refer to the DIV HTML element
                {
                    scrollsPageOnFocus: false,
                    nodeTemplateMap: myDiagram.nodeTemplateMap,  // share the templates used by myDiagram
                    model: new go.GraphLinksModel([  // specify the contents of the Palette
                      { category: "Start", text: "Start" },
                      { text: "Step" },
                      { text: "???", figure: "Diamond" },
                      { category: "End", text: "End" },
                      { category: "Comment", text: "Comment" }
                    ])
                });

            var c = urlParams["Data"];
            if(c && c.length > 0){
               jQuery.ajax({
                   type: 'POST',                     //GET or POST
                   url: "FlowChart.aspx/GetFile",  //請求的頁面
                   data:  '{fileName: "' + c + '" }',
                    cache: false,   //是否使用快取
                    contentType: 'application/json; charset=UTF-8',
                    dataType: 'json',
                    success: function (result) {   //處理回傳成功事件，當請求成功後此事件會被呼叫
                        myDiagram.model = go.Model.fromJson(result.d);
                    },
                    error: function (result) {   //處理回傳錯誤事件，當請求失敗後此事件會被呼叫
                        //your code here

                    }
                });
            }
            
        } // end init

        function showPorts(node, show) {
            var diagram = node.diagram;
            if (!diagram || diagram.isReadOnly || !diagram.allowLink) return;
            node.ports.each(function (port) {
                port.stroke = (show ? "white" : null);
            });
        }

        function SaveData() {
            $('#<%=hiddenfieldData.ClientID%>').val(myDiagram.model.toJson());
            var a = $('#<%=textboxName.ClientID%>').val();
            if (a == null || a.length == 0) return false;
            else return true;
        }

        function LoadData() {
            $('#<%=textboxName.ClientID%>').val($('#<%=dropdownlistHistory.ClientID%> option:selected').text());
            var a = $('#<%=dropdownlistHistory.ClientID%> option:selected').val();
            myDiagram.model = go.Model.fromJson(a);
            return false;
        }

        function SubmitClick() {
            if (myDiagram.model.toJson().length > 0) {
                var image = myDiagram.makeImage();
                var a = new Date().YYYYMMDDHHMMSS();
                $('#<%=hiddenfieldName.ClientID%>').val(a);
                $('#<%=hiddenfieldData.ClientID%>').val(myDiagram.model.toJson());
                window.opener.SetChart(image.outerHTML.replace('<img', '<img $' + a + '$ '));
            }
        }
        Object.defineProperty(Date.prototype, 'YYYYMMDDHHMMSS', {
            value: function () {
                function pad2(n) {  // always returns a string
                    return (n < 10 ? '0' : '') + n;
                }

                return this.getFullYear() +
                       pad2(this.getMonth() + 1) +
                       pad2(this.getDate()) +
                       pad2(this.getHours()) +
                       pad2(this.getMinutes()) +
                       pad2(this.getSeconds());
            }
        });
    </script>
</body>
</html>
