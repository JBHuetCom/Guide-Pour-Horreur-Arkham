object FrmInitialisationPartie: TFrmInitialisationPartie
  Left = 0
  Top = 0
  Caption = 'InitialisationPartie'
  ClientHeight = 500
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 13
  object LabelTitre: TLabel
    Left = 16
    Top = 16
    Width = 164
    Height = 17
    Caption = 'Initialisation de la partie'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -14
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelInvestigateurDepart: TLabel
    Left = 16
    Top = 216
    Width = 119
    Height = 13
    Caption = 'Investigateur de d'#233'part:'
  end
  object PanelGrandAncien: TPanel
    Left = 16
    Top = 56
    Width = 569
    Height = 145
    BevelOuter = bvNone
    TabOrder = 0
    object LabelGrandAncien: TLabel
      Left = 8
      Top = 8
      Width = 68
      Height = 13
      Caption = 'Grand Ancien:'
    end
    object ImageGrandAncien: TImage
      Left = 384
      Top = 4
      Width = 128
      Height = 128
    end
    object LabelTailleEchelleDestin: TLabel
      Left = 8
      Top = 40
      Width = 130
      Height = 13
      Caption = 'Taille de l'#39#233'chelle du destin:'
    end
    object ComboGrandAncien: TComboBox
      Left = 112
      Top = 4
      Width = 257
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = ComboGrandAncienChange
    end
    object EditTailleEchelleDestin: TEdit
      Left = 168
      Top = 36
      Width = 100
      Height = 21
      TabOrder = 1
    end
  end
  object ComboInvestigateurDepart: TComboBox
    Left = 176
    Top = 212
    Width = 257
    Height = 21
    Style = csDropDownList
    TabOrder = 1
  end
  object PanelReglesSpeciales: TPanel
    Left = 16
    Top = 256
    Width = 569
    Height = 185
    BevelOuter = bvNone
    Caption = 'R'#232'gles sp'#233'ciales'
    TabOrder = 2
    object LabelReglesEnSommeil: TLabel
      Left = 8
      Top = 8
      Width = 95
      Height = 13
      Caption = 'En sommeil: Aucune'
      WordWrap = True
    end
    object LabelReglesSpecial: TLabel
      Left = 8
      Top = 32
      Width = 111
      Height = 26
      Caption = 'Sp'#233'ciale: Aucune'
      WordWrap = True
    end
    object LabelReglesAdorateurs: TLabel
      Left = 8
      Top = 56
      Width = 97
      Height = 13
      Caption = 'Adorateurs: Aucune'
      WordWrap = True
    end
    object LabelReglesBataille: TLabel
      Left = 8
      Top = 80
      Width = 77
      Height = 13
      Caption = 'Bataille: Aucune'
      WordWrap = True
    end
  end
  object BoutonOK: TButton
    Left = 352
    Top = 456
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
    OnClick = BoutonOKClick
  end
  object BoutonAnnuler: TButton
    Left = 440
    Top = 456
    Width = 75
    Height = 25
    Caption = 'Annuler'
    ModalResult = 2
    TabOrder = 3
  end
end
