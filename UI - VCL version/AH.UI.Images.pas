unit AH.UI.Images;

  interface

    uses

      System.SysUtils, System.IOUtils,
      Vcl.ExtCtrls;

    /// <summary>
    /// Charge une image dans AImage si ACheminRelatif est renseigné et que le fichier existe
    /// sous ADossierBase ; masque et vide AImage sinon (chemin vide, fichier absent, ou format
    /// non reconnu). Ne lève jamais d'exception : les illustrations sont un confort, jamais une
    /// condition de fonctionnement de l'application.
    /// </summary>
    procedure ChargerImageSiPossible(AImage : TImage; const ACheminRelatif, ADossierBase : string);

  implementation

    procedure ChargerImageSiPossible(AImage : TImage; const ACheminRelatif, ADossierBase : string);
      var
        CheminComplet : string;
      begin
        AImage.Picture.Graphic := nil;
        AImage.Visible := False;

        if ACheminRelatif = EmptyStr then
          Exit;

        CheminComplet := TPath.Combine(ADossierBase, ACheminRelatif);
        if not TFile.Exists(CheminComplet) then
          Exit;

        try
          AImage.Picture.LoadFromFile(CheminComplet);
          AImage.Visible := True;
        except
          AImage.Picture.Graphic := nil;
          AImage.Visible := False;
        end;
      end;

end.
