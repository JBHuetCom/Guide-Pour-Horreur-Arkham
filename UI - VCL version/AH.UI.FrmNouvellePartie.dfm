object FrmNouvellePartie: TFrmNouvellePartie
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Nouvelle partie'
  ClientHeight = 412
  ClientWidth = 532
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object LabelTitre: TLabel
    Left = 12
    Top = 12
    Width = 259
    Height = 25
    Caption = #201'tape 1 / 2 : Joueurs humains'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelErreur: TLabel
    Left = 12
    Top = 336
    Width = 3
    Height = 15
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object PanelJoueurs: TPanel
    Left = 12
    Top = 48
    Width = 496
    Height = 318
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 0
      Top = 0
      Width = 340
      Height = 21
      Caption = 'Ajoutez chaque joueur humain autour de la table.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblComboPremierJoueur: TLabel
      Left = 9
      Top = 286
      Width = 117
      Height = 21
      Caption = 'Premier Joueur : '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object EditNomJoueur: TEdit
      Left = 0
      Top = 28
      Width = 300
      Height = 23
      TabOrder = 0
    end
    object BoutonAjouterJoueur: TButton
      Left = 308
      Top = 27
      Width = 100
      Height = 26
      Caption = 'Ajouter'
      TabOrder = 1
      OnClick = GererClicAjouterJoueur
    end
    object ListeJoueurs: TListBox
      Left = 0
      Top = 64
      Width = 300
      Height = 200
      ItemHeight = 15
      TabOrder = 2
      OnClick = GererSelectionListe
    end
    object BoutonSupprimerJoueur: TButton
      Left = 308
      Top = 64
      Width = 100
      Height = 26
      Caption = 'Supprimer'
      TabOrder = 3
      OnClick = GererClicSupprimerJoueur
    end
    object ComboPremierJoueur: TComboBox
      Left = 135
      Top = 286
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 4
    end
  end
  object PanelInvestigateurs: TPanel
    Left = 12
    Top = 48
    Width = 496
    Height = 280
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    object Label2: TLabel
      Left = 0
      Top = 0
      Width = 432
      Height = 21
      Caption = 'Ajoutez chaque investigateur en jeu et indiquez qui le contr'#244'le.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object ComboNomInvestigateur: TComboBox
      Left = 0
      Top = 28
      Width = 220
      Height = 23
      TabOrder = 0
    end
    object ComboJoueurControleur: TComboBox
      Left = 228
      Top = 28
      Width = 150
      Height = 23
      Style = csDropDownList
      TabOrder = 1
    end
    object BoutonAjouterInvestigateur: TButton
      Left = 388
      Top = 27
      Width = 100
      Height = 26
      Caption = 'Ajouter'
      TabOrder = 2
      OnClick = GererClicAjouterInvestigateur
    end
    object ListeInvestigateurs: TListBox
      Left = 0
      Top = 64
      Width = 380
      Height = 200
      ItemHeight = 15
      TabOrder = 3
      OnClick = GererSelectionListe
    end
    object BoutonSupprimerInvestigateur: TButton
      Left = 388
      Top = 64
      Width = 100
      Height = 26
      Caption = 'Supprimer'
      TabOrder = 4
      OnClick = GererClicSupprimerInvestigateur
    end
  end
  object BoutonPrecedent: TButton
    Left = 12
    Top = 372
    Width = 110
    Height = 28
    Caption = '< Pr'#233'c'#233'dent'
    TabOrder = 2
    OnClick = GererClicPrecedent
  end
  object BoutonSuivant: TButton
    Left = 398
    Top = 372
    Width = 110
    Height = 28
    Caption = 'Suivant >'
    Default = True
    TabOrder = 3
    OnClick = GererClicSuivant
  end
end
