CKEDITOR.plugins.add('flowchart', {
    icons: 'flowchart',
    init: function (editor) {
        editor.addCommand('insertflowchart', {
            exec: function (editor) {
                var returnVal;
                var newWindow = window.open('FlowChart', 'FlowChart.aspx', "width=800,height=400");
            }
        });
        editor.ui.addButton('Flowchart', {
            label: 'Insert Flowchart',
            command: 'insertflowchart',
            toolbar: 'insert'
        });
    }
});