unit AH.Core.Conseils;

  interface

    uses
      System.SysUtils, System.Generics.Collections;

    type

      EConseilsInvalidesException = class(Exception);

      /// <summary>Un conseil stratégique associé à une étape du guide, affiché en complément du texte de règle.</summary>
      TConseil = record
        Texte : string;
        /// <summary>Référence optionnelle de la source du conseil (ex. nom du site). Purement informatif.</summary>
        Source : string;
      end;

      /// <summary>
      /// Charge et expose les conseils stratégiques définis dans un fichier de configuration JSON,
      /// indexés par l'identifiant du nœud d'étape (TNoeudEtape.Id) auquel ils se rattachent.
      /// L'affichage effectif de ces conseils dans l'UI est gouverné par
      /// TParametresApplication.AfficherConseils, pas par cette classe : celle-ci se contente
      /// d'exposer le contenu, elle ne décide jamais s'il doit être montré.
      /// </summary>
      TGestionnaireConseils = class
        private
          FConseilsParEtape : TObjectDictionary<string, TList<TConseil>>;
        public
          constructor Create;
          destructor Destroy; override;

          /// <param name="ACheminFichier">Chemin d'un fichier .json conforme au schéma de conseils.</param>
          /// <exception cref="EFileNotFoundException">Levée si ACheminFichier n'existe pas.</exception>
          /// <exception cref="EConseilsInvalidesException">
          /// Levée si le JSON est malformé ou si une entrée n'a pas de "IdEtape".
          /// </exception>
          procedure ChargerDepuisFichier(const ACheminFichier : string);

          /// <param name="AIdEtape">Identifiant du nœud d'étape pour lequel chercher des conseils.</param>
          /// <returns>Les conseils associés à cette étape, dans l'ordre du fichier de configuration. Tableau vide si aucun.</returns>
          function ConseilsPour(const AIdEtape : string): TArray<TConseil>;
      end;

  implementation

    uses
      SuperObject;

    { TGestionnaireConseils }

    constructor TGestionnaireConseils.Create;
      begin
        inherited Create;

        FConseilsParEtape := TObjectDictionary<string, TList<TConseil>>.Create([doOwnsValues]);
      end;

    destructor TGestionnaireConseils.Destroy;
      begin
        FConseilsParEtape.Free;

        inherited;
      end;

    procedure TGestionnaireConseils.ChargerDepuisFichier(const ACheminFichier : string);
      var
        i : Integer;
        IdEtape : string;
        Liste : TList<TConseil>;
        Racine, Entree : ISuperObject;
        Entrees : ISuperArray;
        Conseil : TConseil;
      begin
        try
          if not FileExists(ACheminFichier) then
            raise EFileNotFoundException.CreateFmt('Fichier de conseils introuvable : "%s".',
                                                   [ACheminFichier]);

          Racine := TSuperObject.ParseFile(ACheminFichier, False);
          if Racine = nil then
            raise EConseilsInvalidesException.CreateFmt('JSON invalide dans le fichier "%s".',
                                                        [ACheminFichier]);

          Entrees := Racine.A['Conseils'];
          if Entrees = nil then
            raise EConseilsInvalidesException.CreateFmt(
              'Le fichier "%s" ne contient pas de tableau racine "Conseils".',
              [ACheminFichier]);

          FConseilsParEtape.Clear;
          for i := 0 to Entrees.Length - 1 do
            begin
              Entree := Entrees.O[i];
              IdEtape := Entree.S['IdEtape'];
              if IdEtape = EmptyStr then
                raise EConseilsInvalidesException.CreateFmt(
                  'Un conseil sans "IdEtape" a été rencontré dans "%s".',
                  [ACheminFichier]);

              Conseil.Texte := Entree.S['Texte'];
              Conseil.Source := Entree.S['Source'];

              if not FConseilsParEtape.TryGetValue(IdEtape, Liste) then
                begin
                  Liste := TList<TConseil>.Create;
                  FConseilsParEtape.Add(IdEtape, Liste);
                end;
              Liste.Add(Conseil);
            end;
        finally
          Liste := nil;
        end;
      end;

    function TGestionnaireConseils.ConseilsPour(const AIdEtape : string): TArray<TConseil>;
      var
        Liste: TList<TConseil>;
      begin
        if FConseilsParEtape.TryGetValue(AIdEtape, Liste) then
          Result := Liste.ToArray
        else
          Result := [];
      end;

end.
