object FrameEtape: TFrameEtape
  Left = 0
  Top = 0
  Width = 500
  Height = 300
  TabOrder = 0
  object LabelTitre: TLabel
    Left = 0
    Top = 0
    Width = 500
    Height = 24
    Align = alTop
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
    WordWrap = True
    ExplicitWidth = 480
  end
  object LabelTexte: TLabel
    Left = 0
    Top = 24
    Width = 500
    Height = 100
    Align = alTop
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    WordWrap = True
    ExplicitTop = 32
    ExplicitWidth = 480
  end
  object PanelInstruction: TPanel
    Left = 0
    Top = 140
    Width = 480
    Height = 40
    BevelOuter = bvNone
    TabOrder = 0
    Visible = False
    object BoutonContinuer: TButton
      Left = 0
      Top = 0
      Width = 160
      Height = 30
      Caption = #201'tape suivante'
      Default = True
      TabOrder = 0
      OnClick = GererClicContinuer
    end
  end
  object PanelChoix: TPanel
    Left = 0
    Top = 140
    Width = 480
    Height = 140
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
  end
  object PanelSaisie: TPanel
    Left = 0
    Top = 140
    Width = 480
    Height = 80
    BevelOuter = bvNone
    TabOrder = 2
    Visible = False
    object LabelErreurSaisie: TLabel
      Left = 0
      Top = 34
      Width = 480
      Height = 20
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
    object EditSaisie: TEdit
      Left = 0
      Top = 0
      Width = 200
      Height = 23
      TabOrder = 0
    end
    object ComboSaisie: TComboBox
      Left = 0
      Top = 0
      Width = 200
      Height = 23
      Style = csDropDownList
      TabOrder = 2
      Visible = False
    end
    object BoutonValiderSaisie: TButton
      Left = 208
      Top = 0
      Width = 100
      Height = 26
      Caption = 'Valider'
      Default = True
      TabOrder = 1
      OnClick = GererClicValiderSaisie
    end
  end
end
