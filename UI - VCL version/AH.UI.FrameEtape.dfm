object FrameEtape: TFrameEtape
  Left = 0
  Top = 0
  Width = 500
  Height = 300
  TabOrder = 0
  object LabelTitre: TLabel
    Left = 0
    Top = 0
    Width = 480
    Height = 24
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
    WordWrap = True
  end
  object LabelTexte: TLabel
    Left = 0
    Top = 32
    Width = 480
    Height = 100
    AutoSize = False
    WordWrap = True
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
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object EditSaisie: TEdit
      Left = 0
      Top = 0
      Width = 200
      Height = 24
      TabOrder = 0
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
