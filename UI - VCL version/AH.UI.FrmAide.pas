unit AH.UI.FrmAide;

  interface

    uses
      Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
      Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, SHDocVw;

    type
      TFrmAide = class(TForm)
        public
          procedure AfficherFichier(const ACheminHtml : string);
        published
          WebBrowserAide: TWebBrowser;
      end;

    var
      FrmAide: TFrmAide;

  implementation

    uses

      System.IOUtils;

    {$R *.dfm}

    procedure TFrmAide.AfficherFichier(const ACheminHtml : string);
      begin
        if TFile.Exists(ACheminHtml) then
          WebBrowserAide.Navigate('file:///' + StringReplace(ACheminHtml, '\', '/', [rfReplaceAll]))
        else
          WebBrowserAide.Navigate('about:blank');
        Show; // Non-modal : reste au-dessus sans bloquer FrmPrincipal.
      end;

end.
