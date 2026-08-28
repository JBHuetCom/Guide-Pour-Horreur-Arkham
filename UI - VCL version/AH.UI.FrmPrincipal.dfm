object FrmPrincipal: TFrmPrincipal
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Horreur '#224' Arkham '#8212' Guide de partie'
  ClientHeight = 800
  ClientWidth = 1200
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object PanelEnTete: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 10
    Padding.Top = 10
    Padding.Right = 10
    Padding.Bottom = 10
    TabOrder = 0
    object LabelEnTete: TLabel
      Left = 12
      Top = 10
      Width = 5
      Height = 25
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LabelIdTechnique: TLabel
      Left = 12
      Top = 32
      Width = 7
      Height = 14
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
    end
  end
  object PanelBas: TPanel
    Left = 0
    Top = 752
    Width = 1200
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object BoutonPrecedent: TButton
      Left = 12
      Top = 10
      Width = 110
      Height = 28
      Caption = '< Pr'#233'c'#233'dent'
      TabOrder = 0
      OnClick = GererClicPrecedent
    end
    object BoutonReveilManuel: TButton
      Left = 132
      Top = 10
      Width = 260
      Height = 28
      Caption = 'Le Grand Ancien s'#39'est r'#233'veill'#233
      TabOrder = 1
      OnClick = GererClicReveilManuel
    end
    object BoutonTerminerPartie: TButton
      Left = 400
      Top = 10
      Width = 160
      Height = 28
      Caption = 'Terminer la partie'
      TabOrder = 2
      OnClick = GererClicTerminerPartie
    end
    object CheckBoxAfficherConseils: TCheckBox
      Left = 700
      Top = 14
      Width = 160
      Height = 20
      Caption = 'Afficher les conseils'
      TabOrder = 3
      OnClick = GererClicAfficherConseils
    end
  end
  object PanelConseils: TPanel
    Left = 920
    Top = 116
    Width = 280
    Height = 576
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 56
    object MemoConseils: TMemo
      Left = 0
      Top = 0
      Width = 280
      Height = 576
      Align = alClient
      Color = clInfoBk
      EditMargins.Left = 10
      EditMargins.Right = 10
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object PanelRegleGrandAncien: TPanel
    Left = 0
    Top = 692
    Width = 1200
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = []
    Padding.Left = 10
    Padding.Top = 10
    Padding.Right = 10
    Padding.Bottom = 10
    ParentBackground = False
    ParentFont = False
    TabOrder = 3
    object LabelRegleGrandAncien: TLabel
      Left = 10
      Top = 10
      Width = 1180
      Height = 40
      Align = alClient
      Alignment = taCenter
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      WordWrap = True
      ExplicitWidth = 4
      ExplicitHeight = 21
    end
  end
  object PanelCapacite: TPanel
    Left = 0
    Top = 56
    Width = 1200
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 10
    Padding.Top = 10
    Padding.Right = 10
    Padding.Bottom = 10
    TabOrder = 4
    ExplicitTop = 632
    object LabelCapacite: TLabel
      Left = 10
      Top = 10
      Width = 1180
      Height = 40
      Align = alClient
      Alignment = taCenter
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
      Layout = tlCenter
      WordWrap = True
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 4
      ExplicitHeight = 21
    end
  end
  inline FrameEtape: TFrameEtape
    Left = 0
    Top = 116
    Width = 920
    Height = 576
    Align = alClient
    Padding.Left = 10
    Padding.Top = 10
    Padding.Right = 10
    Padding.Bottom = 10
    TabOrder = 5
    ExplicitTop = 56
    ExplicitWidth = 920
    ExplicitHeight = 576
    inherited LabelTitre: TLabel
      Left = 10
      Top = 10
      Width = 900
      Height = 25
      AutoSize = True
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 5
      ExplicitHeight = 25
    end
    inherited LabelTexte: TLabel
      Left = 10
      Top = 35
      Width = 900
      Height = 21
      AutoSize = True
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 24
      ExplicitWidth = 4
      ExplicitHeight = 21
    end
    inherited PanelInstruction: TPanel
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited PanelChoix: TPanel
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited PanelSaisie: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited LabelErreurSaisie: TLabel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited EditSaisie: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited ComboSaisie: TComboBox
        StyleElements = [seFont, seClient, seBorder]
      end
    end
  end
  object PanelEtatTerminal: TPanel
    Left = 0
    Top = 116
    Width = 920
    Height = 576
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 6
    Visible = False
    ExplicitTop = 56
    object LabelEtatTerminal: TLabel
      Left = 20
      Top = 20
      Width = 5
      Height = 25
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object BoutonNouvellePartie: TButton
      Left = 20
      Top = 90
      Width = 160
      Height = 30
      Caption = 'Nouvelle partie'
      TabOrder = 0
      OnClick = GererClicNouvellePartie
    end
  end
end
