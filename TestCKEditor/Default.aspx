<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master"  AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="TestCKEditor._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <script src="Scripts/ckeditor/ckeditor.js"></script>
    <textarea name="editor1" id="editor1" rows="100" cols="100"> </textarea>
    <script>
        var editor = CKEDITOR.replace('editor1');
        CKEDITOR.config.extraPlugins = 'flowchart';
        CKEDITOR.config.height = 700;
        editor.on('instanceReady', function (e) {
            editor.addCommand("flowchartCommand", {
                exec: function (editor) {       
                    var newWindow = window.open('FlowChart.aspx?Data=' + editor.document.getBody().getHtml().split('$')[1], 'FlowChart', "width=800,height=400");
                }
            });

            var myCommand = {
                label: 'Flow Chart Edit',
                command: 'flowchartCommand',
                group: 'image'
            };


            editor.contextMenu.addListener(function (element, selection) {
                if (element.is('img'))
                    return {
                        flowchartCommand: CKEDITOR.TRISTATE_OFF
                    };
            });

            editor.addMenuItems({
                flowchartCommand: {
                    label: 'Edit Flow Chart',
                    command: 'flowchartCommand',
                    group: 'image',
                    order: 1
                }
            });
        });

        function SetChart(data) {
            var newElement = CKEDITOR.dom.element.createFromHtml(data, CKEDITOR.document);
            CKEDITOR.instances.editor1.insertElement(newElement);
        }
    </script>
</asp:Content>
