program ArkhamHorrorGuideTests;

  {$IFNDEF TESTINSIGHT}
  {$APPTYPE CONSOLE}
  {$ENDIF}

  {$STRONGLINKTYPES ON}
  uses
  FastMM5,
  {$IFDEF DEBUG MEMOIRE}
  DUnitX.MemoryLeakMonitor.FastMM5,
  {$ENDIF }
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  System.IOUtils,
  superobject,
  AH.Core.Types,
  AH.Core.Noeud,
  AH.Core.Moteur,
  AH.Core.Capacites,
  AH.Core.Conseils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  AH.Tests.Moteur in 'AH.Tests.Moteur.pas',
  AH.Tests.EvaluateurCondition in 'AH.Tests.EvaluateurCondition.pas',
  AH.Tests.ChargeurContenu in 'AH.Tests.ChargeurContenu.pas',
  AH.Tests.Contexte in 'AH.Tests.Contexte.pas',
  AH.Tests.Conseils in 'AH.Tests.Conseils.pas',
  AH.Tests.Capacites in 'AH.Tests.Capacites.pas',
  AH.Tests.Parametres in 'AH.Tests.Parametres.pas',
  AH.Tests.Session in 'AH.Tests.Session.pas',
  AH.Tests.ConstructeurPartie in 'AH.Tests.ConstructeurPartie.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
  {$IFNDEF TESTINSIGHT}
  var
    runner : ITestRunner;
    results : IRunResults;
    logger : ITestLogger;
    nunitLogger : ITestLogger;
    GFastMMLogFileName : string;
    GFastMMStateFileName : string;
	CurrentThread: TThread;
  {$ENDIF}

  procedure AmorcerLesSpecialisationsGeneriques;
  { Certaines spécialisations génériques (TDictionary<...>, TObjectList<...>, TList<...>, etc.)
    allouent, à leur toute première utilisation dans le process, un comparateur par défaut mis
    en cache pour la durée de vie de l'application (System.Generics.Defaults). Allocation
    normale et volontaire côté RTL, jamais libérée avant la fin du process — FastMM5/DUnitX la
    signale néanmoins comme fuite et l'attribue au premier test qui la déclenche. On amorce donc
    ici, avant l'exécution des tests, chaque spécialisation utilisée par l'application, pour que
    ce coût unique soit payé hors de la fenêtre de mesure des fuites. }
    var
      NoeudSequence, NoeudCondition : TNoeudEtape;
      Capacites : TDictionary<string, TCapaciteInvestigateur>;
      Conseils : TObjectDictionary<string, TList<TConseil>>;
      ListeConseils : TList<TConseil>;
      Pile : TList<TFrameParcours>;
      Historique : TStack<TInstantane>;
      TemporaryFilePath : string;
      Utf8Encoding : TEncoding;
      Utf8ByteCount : Integer;
      JsonWarmup : ISuperObject;
	    RttiContext : TSuperRttiContext;
    begin
      // L'accès au thread courant peut créer paresseusement un TExternalThread
      // global de la RTL. Son initialisation est effectuée avant le runner afin
      // que DUnitX ne l'attribue pas au premier test qui manipule des fichiers,
      // du JSON ou des assertions.
      CurrentThread := TThread.Current;
      if not Assigned(CurrentThread) then
      raise EInvalidOpException.Create(
        'Impossible d''amorcer l''enveloppe RTL du thread principal.');
		  
	    NoeudSequence := TNoeudEtape.Create('amorce_sequence', ntSequence);
      NoeudSequence.Free;
	  
      NoeudCondition := TNoeudEtape.Create('amorce_condition', ntCondition);
      NoeudCondition.Free;

      Capacites := TDictionary<string, TCapaciteInvestigateur>.Create;
      Capacites.Free;

      Conseils := TObjectDictionary<string, TList<TConseil>>.Create([doOwnsValues]);
      Conseils.Free;

      ListeConseils := TList<TConseil>.Create;
      ListeConseils.Free;

      Pile := TList<TFrameParcours>.Create;
      Pile.Free;

      Historique := TStack<TInstantane>.Create;
      Historique.Free;

      // TPath et TFile peuvent initialiser des ressources internes à leur première
      // utilisation. L'amorçage est volontairement réalisé avant l'exécution des
      // tests afin que FastMM5 ne l'attribue pas au premier test utilisateur.
      TemporaryFilePath := TPath.Combine(
        TPath.GetTempPath,
        'arkham_horror_guide_warmup_file_does_not_exist.tmp');

      TFile.Exists(TemporaryFilePath);

      // TFile.WriteAllText utilise l'encodage UTF-8 par défaut. Cette initialisation
      // est également effectuée hors de la fenêtre de surveillance des tests.
      Utf8Encoding := TEncoding.UTF8;
      Utf8ByteCount := Utf8Encoding.GetByteCount(EmptyStr);

      if Utf8ByteCount <> 0 then
        raise EInvalidOpException.Create(
          'L''amorçage UTF-8 a produit une taille inattendue.');

      // SuperObject initialise certaines ressources internes lors de la première
      // analyse JSON. Cette initialisation est effectuée avant la surveillance
      // DUnitX/FastMM5 afin de ne pas être attribuée au premier test utilisateur.
      JsonWarmup := SO('{"Warmup":true}');

      if not Assigned(JsonWarmup) or not JsonWarmup.B['Warmup'] then
        raise EInvalidOpException.Create(
          'L''amorçage du parseur SuperObject a échoué.');
			
      RttiContext := TSuperRttiContext.Create;
      RttiContext.Free;
    end;

	/// <summary>
	/// Retourne le répertoire contenant l'exécutable de tests.
	/// Ce répertoire existe avant l'exécution et sert de destination stable pour
	/// les diagnostics FastMM5.
	/// </summary>
	/// <returns>Chemin absolu du répertoire de l'exécutable de tests, sans séparateur final.</returns>
	/// <exception cref="System.SysUtils.EInvalidOp">
	/// Levée si le chemin de l'exécutable ne permet pas de déterminer un répertoire de diagnostic exploitable.
	/// </exception>
	function GetFastMMDiagnosticsDirectory: string;
		begin
		  Result := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

		  if Result = EmptyStr then
			raise EInvalidOpException.Create(
			  'Impossible de déterminer le répertoire de diagnostic FastMM5.');
		end;

	/// <summary>
	/// Configure temporairement FastMM5 pour produire des rapports de diagnostic
	/// dans le même répertoire que l'exécutable de tests.
	/// Cette configuration est réservée aux investigations et ne doit pas être
	/// activée dans les builds de livraison.
	/// </summary>
	procedure ConfigureFastMMDiagnostics;
		var
		  DiagnosticsDirectory: string;
		begin
		  DiagnosticsDirectory := GetFastMMDiagnosticsDirectory;

		  GFastMMLogFileName := TPath.Combine(
			DiagnosticsDirectory,
			'ArkhamHorrorGuideTests.FastMM.Events.log');

		  GFastMMStateFileName := TPath.Combine(
			DiagnosticsDirectory,
			'ArkhamHorrorGuideTests.FastMM.State.log');

		  // Les chaînes sont globales afin que les pointeurs transmis à FastMM restent
		  // valides pendant toute l'exécution du processus.
		  FastMM_SetEventLogFilename(PWideChar(GFastMMLogFileName));
		  FastMM_DeleteEventLogFile;

		  FastMM_LogToFileEvents := FastMM_LogToFileEvents +
			[mmetUnexpectedMemoryLeakDetail, mmetUnexpectedMemoryLeakSummary];

		  FastMM_OutputDebugStringEvents := FastMM_OutputDebugStringEvents +
			[mmetUnexpectedMemoryLeakDetail, mmetUnexpectedMemoryLeakSummary];

		  FastMM_EnterDebugMode;
		  FastMM_SetDebugModeStackTraceEntryCount(32);

		  System.Writeln('FastMM working directory: ' + GetCurrentDir);
		  System.Writeln('FastMM event log: ' + GFastMMLogFileName);
		  System.Writeln('FastMM state log: ' + GFastMMStateFileName);
		end;

begin
  {$IFDEF DEBUG MEMOIRE}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  {$IFDEF TESTINSIGHT}
  {$IFDEF DEBUG}
  ConfigureFastMMDiagnostics;
  {$ENDIF}
  TestInsight.DUnitX.RunRegisteredTests;
 {$ELSE}
  try
    {$IFDEF DEBUG MEMOIRE}
    ConfigureFastMMDiagnostics;
    AmorcerLesSpecialisationsGeneriques;
    {$ENDIF}

    //Pause par défaut en sortie ; CheckCommandLine peut écraser cette valeur si un
    //argument de ligne de commande explicite est fourni (utile en CI).
    TDUnitX.Options.ExitBehavior := TDUnitXExitBehavior.Pause;
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
      begin
        logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
        runner.AddLogger(logger);
      end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;

    if not FastMM_LogStateToFile(PWideChar(GFastMMStateFileName)) then
      System.Writeln('FastMM n''a pas pu écrire le rapport d''état : ' + GFastMMStateFileName)
    else
      if not TFile.Exists(GFastMMStateFileName) then
        System.Writeln('FastMM a retourné True, mais le fichier est introuvable : ' + GFastMMStateFileName)
      else
        System.Writeln('Rapport d''état FastMM créé : ' + GFastMMStateFileName);

    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
      begin
        System.Write('Done.. press <Enter> key to quit.');
        System.Readln;
      end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ' : ', E.Message);
  end;
 {$ENDIF}

end.
