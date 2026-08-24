unit AH.Core.Capacites;

  interface

    uses
      System.SysUtils, System.Generics.Collections;

    type

      ECapacitesInvalidesException = class(Exception);

      /// <summary>Domaine principal dans lequel la capacité spéciale d'un investigateur excelle.</summary>
      TDomaineCapacite = (dcEnquete, dcCombat, dcMagie, dcDeplacement, dcSocial, dcAutre);

      /// <summary>Capacité spéciale propre à un investigateur (feuille Investigateur, § "Capacité Unique", page 21).</summary>
      TCapaciteInvestigateur = record
        NomInvestigateur : string;
        Domaine : TDomaineCapacite;
        Description : string;
      end;

      /// <summary>
      /// Charge et expose les capacités spéciales des investigateurs, définies dans un fichier de
      /// configuration JSON, indexées par nom d'investigateur. Simple lookup : c'est à l'UI de
      /// décider quand afficher une capacité (typiquement pendant le tour de l'investigateur
      /// concerné et pendant la bataille finale).
      /// </summary>
      TGestionnaireCapacites = class
        private
          FCapacitesParInvestigateur : TDictionary<string, TCapaciteInvestigateur>;
        public
          constructor Create;
          destructor Destroy; override;

          /// <param name="ACheminFichier">Chemin d'un fichier .json conforme au schéma de capacités.</param>
          /// <exception cref="EFileNotFoundException">Levée si ACheminFichier n'existe pas.</exception>
          /// <exception cref="ECapacitesInvalidesException">
          /// Levée si le JSON est malformé, si "NomInvestigateur" est manquant, ou si "Domaine"
          /// ne correspond à aucune valeur connue de TDomaineCapacite.
          /// </exception>
          procedure ChargerDepuisFichier(const ACheminFichier : string);

          /// <param name="ANomInvestigateur">Nom de l'investigateur recherché, insensible à la casse.</param>
          /// <param name="ACapacite">Capacité trouvée si la fonction retourne True.</param>
          /// <returns>True si une capacité est déclarée pour cet investigateur, False sinon.</returns>
          function TryObtenirCapacite(const ANomInvestigateur : string; out ACapacite : TCapaciteInvestigateur) : Boolean;
      end;

  implementation

    uses
      SuperObject;

    function TryStrToDomaineCapacite(const AText : string; out ADomaine : TDomaineCapacite) : Boolean;
    begin
      Result := True;
      if SameText(AText, 'Enquête') then
         ADomaine := dcEnquete
      else
        if SameText(AText, 'Combat') then
          ADomaine := dcCombat
        else
          if SameText(AText, 'Magie') then
            ADomaine := dcMagie
          else
            if SameText(AText, 'Deplacement') then
              ADomaine := dcDeplacement
            else
              if SameText(AText, 'Social') then
                ADomaine := dcSocial
              else
                if SameText(AText, 'Autre') then
                  ADomaine := dcAutre
                else
                  Result := False;
    end;

    { TGestionnaireCapacites }

    constructor TGestionnaireCapacites.Create;
      begin
        inherited Create;

        FCapacitesParInvestigateur := TDictionary<string, TCapaciteInvestigateur>.Create;
      end;

    destructor TGestionnaireCapacites.Destroy;
      begin
        FCapacitesParInvestigateur.Free;

        inherited;
      end;

    procedure TGestionnaireCapacites.ChargerDepuisFichier(const ACheminFichier : string);
      var
        Racine, Entree : ISuperObject;
        Entrees : ISuperArray;
        i : Integer;
        Capacite : TCapaciteInvestigateur;
        TexteDomaine : string;
      begin
        if not FileExists(ACheminFichier) then
          raise EFileNotFoundException.CreateFmt('Fichier de capacités introuvable : "%s".',
                                                 [ACheminFichier]);

        Racine := TSuperObject.ParseFile(ACheminFichier, False);
        if Racine = nil then
          raise ECapacitesInvalidesException.CreateFmt('JSON invalide dans le fichier "%s".',
                                                       [ACheminFichier]);

        Entrees := Racine.A['Capacites'];
        if Entrees = nil then
          raise ECapacitesInvalidesException.CreateFmt(
            'Le fichier "%s" ne contient pas de tableau racine "Capacites".',
            [ACheminFichier]);

        FCapacitesParInvestigateur.Clear;
        for i := 0 to Entrees.Length - 1 do
          begin
            Entree := Entrees.O[i];
            Capacite.NomInvestigateur := Entree.S['NomInvestigateur'];
            if Capacite.NomInvestigateur = EmptyStr then
              raise ECapacitesInvalidesException.CreateFmt(
                'Une capacité sans "NomInvestigateur" a été rencontrée dans "%s".',
                [ACheminFichier]);

            TexteDomaine := Entree.S['Domaine'];
            if not TryStrToDomaineCapacite(TexteDomaine, Capacite.Domaine) then
              raise ECapacitesInvalidesException.CreateFmt(
                'Capacité de "%s" : domaine inconnu "%s".',
                [Capacite.NomInvestigateur, TexteDomaine]);

            Capacite.Description := Entree.S['Description'];

            FCapacitesParInvestigateur.AddOrSetValue(AnsiLowerCase(Capacite.NomInvestigateur), Capacite);
          end;
      end;

    function TGestionnaireCapacites.TryObtenirCapacite(const ANomInvestigateur : string;
                                                       out ACapacite : TCapaciteInvestigateur): Boolean;
      begin
        Result := FCapacitesParInvestigateur.TryGetValue(AnsiLowerCase(ANomInvestigateur), ACapacite);
      end;

end.
