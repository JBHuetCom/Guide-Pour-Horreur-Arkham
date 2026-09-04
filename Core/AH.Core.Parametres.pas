unit AH.Core.Parametres;

  interface

    type

      /// <summary>
      /// Préférences d'affichage de l'application, persistées entre les sessions. À distinguer de
      /// TContextePartie (état d'une partie en cours) : ce sont des réglages utilisateur, pas des
      /// données de jeu.
      /// </summary>
      TParametresApplication = class
        private
          FAfficherConseils : Boolean;
        public
          /// <summary>Initialise les valeurs par défaut avant tout chargement : conseils affichés.</summary>
          constructor Create;

          /// <param name="ACheminFichier">
          /// Chemin d'un fichier .json de préférences. S'il n'existe pas ou si une clé est absente,
          /// les valeurs par défaut correspondantes sont conservées silencieusement (premier lancement
          /// ou fichier partiellement édité à la main).
          /// </param>
          procedure ChargerDepuisFichier(const ACheminFichier : string);

          /// <param name="ACheminFichier">Chemin du fichier .json à écrire (créé s'il n'existe pas, écrasé sinon).</param>
          procedure SauvegarderDansFichier(const ACheminFichier : string);

          /// <summary>Active ou désactive l'affichage du panneau de conseils stratégiques dans l'UI.</summary>
          property AfficherConseils : Boolean read FAfficherConseils write FAfficherConseils;
      end;

  implementation

    uses
      System.SysUtils, SuperObject;

    { TParametresApplication }

    constructor TParametresApplication.Create;
      begin
        inherited Create;

        FAfficherConseils := True;
      end;

    procedure TParametresApplication.ChargerDepuisFichier(const ACheminFichier : string);
      var
        Racine : ISuperObject;
      begin
        if not FileExists(ACheminFichier) then
          Exit; // Premier lancement : valeurs par défaut conservées.

        Racine := TSuperObject.ParseFile(ACheminFichier, False);
        if Racine = nil then
          Exit; // Fichier corrompu : valeurs par défaut conservées plutôt que de bloquer le démarrage.

        if Racine.O['AfficherConseils'] <> nil then
          FAfficherConseils := Racine.B['AfficherConseils'];
      end;

    procedure TParametresApplication.SauvegarderDansFichier(const ACheminFichier : string);
      var
        Racine : ISuperObject;
      begin
        Racine := SO;
        Racine.B['AfficherConseils'] := FAfficherConseils;
        Racine.SaveTo(ACheminFichier);
      end;

end.
