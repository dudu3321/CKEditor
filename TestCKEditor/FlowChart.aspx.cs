using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace TestCKEditor
{
    public partial class FlowChart : System.Web.UI.Page
    {
        private string connection = ConfigurationManager.ConnectionStrings["g_oa_ConnStr"].ToString();
        DataTable data = new DataTable();
        protected void Page_Load(object sender, EventArgs e)
        {
            GetData();
            if (!IsPostBack) bindDrop();
        }
        protected void GetData()
        {
            using (SqlDataAdapter sqlDataAdapter = new SqlDataAdapter("SELECT * FROM CKEditor", connection))
            {
                data = new DataTable();
                sqlDataAdapter.Fill(data);       
            }
        }
        protected void bindDrop()
        {
            dropdownlistHistory.DataSource = data;
            dropdownlistHistory.DataTextField = "Name";
            dropdownlistHistory.DataValueField = "Dada";
            dropdownlistHistory.DataBind();
        }

        protected void buttonSave_Click(object sender, EventArgs e)
        {
            if (!string.IsNullOrWhiteSpace(textboxName.Text))
            {
                string cmdString = string.Empty;
                if (data.Select("Name = '" + textboxName.Text + "'").Length > 0)
                {
                    cmdString = @"
UPDATE [dbo].[CKEditor]
   SET [Dada] = @Dada
 WHERE Name = @Name";
                }
                else
                {
                    cmdString = @"
INSERT INTO [dbo].[CKEditor]
           ([Name]
           ,[Dada])
     VALUES
           (@Name,
           @Dada)";
                }
                using (SqlConnection cn = new SqlConnection(connection))
                {
                    cn.Open();
                    using (SqlCommand cmd = new SqlCommand(cmdString, cn))
                    {
                        cmd.Parameters.AddWithValue("@Name", textboxName.Text);
                        cmd.Parameters.AddWithValue("@Dada", hiddenfieldData.Value);
                        cmd.ExecuteNonQuery();
                        textboxName.Text = string.Empty;
                        GetData();
                        bindDrop();
                    }
                }
            }
        }

        [WebMethod]
        public static string GetFile(string fileName)
        {
            return File.ReadAllText("D:\\TestCKEditor\\TestCKEditor\\doc\\" + fileName + ".txt");
        }
        

        protected void button1_Click(object sender, EventArgs e)
        {
            string fileName = hiddenfieldName.Value;
            if(!string.IsNullOrWhiteSpace(fileName))
            {
                string path = Server.MapPath("~") + "\\doc\\";
                if (File.Exists(path + fileName + ".txt")) File.Delete(path + fileName + ".txt");
                using (FileStream fs = File.Create(path + fileName + ".txt"))
                {
                    Byte[] info = new UTF8Encoding(true).GetBytes(hiddenfieldData.Value);
                    // Add some information to the file.
                    fs.Write(info, 0, info.Length);
                }
                Response.Write("<script language=javascript>window.close()</script>");
            }
        }
    }
}