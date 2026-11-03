import QtQuick
import QtQuick.Layouts

import "."

Island {
    id: root

    hPad: 3

    readonly property var today: AgentUsageData.today
    readonly property var cycle: AgentUsageData.cycle
    readonly property var windows: AgentUsageData.windows
    readonly property var providers: AgentUsageData.snapshot.providers ?? []
    readonly property int remaining: AgentUsageData.tightestRemaining
    readonly property real totalTokens: Number(cycle?.totalTokens || 0)
    readonly property real todayTokens: Number(today?.totalTokens || 0)
    readonly property real todayCost: Number(today?.costUsd || 0)
    readonly property real recordedTokens: {
        let total = 0
        for (let i = 0; i < providers.length; i++)
            total += Number(providers[i].totalTokens || 0)
        return total
    }
    readonly property bool initialLoad: AgentUsageData.loading && !AgentUsageData.everLoaded

    function limitColor(percent) {
        return percent <= 15 ? Theme.love : percent <= 35 ? Theme.gold : Theme.iris
    }

    function providerModels(providerId) {
        const models = cycle?.models || []
        return models.filter(model => model.provider === providerId)
            .sort((a, b) => Number(b.totalTokens || 0) - Number(a.totalTokens || 0))
            .slice(0, 2)
    }

    function providerIcon(id) {
        if (id === "anthropic") return "󰚩"
        if (id === "openai" || id === "cursor") return "󰗀"
        if (id === "google") return "󰊭"
        if (id === "xai") return "󰉼"
        return "󰚩"
    }

    RowLayout {
        spacing: 4

        Text {
            text: "󰚩"
            color: windows.length ? root.limitColor(root.remaining) : Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
        }

        Text {
            visible: (!AgentUsageData.loading || AgentUsageData.everLoaded) && windows.length > 0
            text: root.remaining + "%"
            color: AgentUsageData.available ? root.limitColor(root.remaining) : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.weight: Font.DemiBold
        }
    }

    HoverHandler { id: hover }

    BarPopup {
        id: popup
        trigger: root
        triggerHovered: hover.hovered
        padding: 14
        align: 1
        contentMinWidth: 390

        ColumnLayout {
            Layout.preferredWidth: 390
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 12
                    color: Theme.alpha(Theme.iris, 0.14)
                    Text {
                        anchors.centerIn: parent
                        text: "󰚩"
                        color: Theme.iris
                        font.family: Theme.fontFamily
                        font.pixelSize: 22
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "Agent activity"
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }
                    Text {
                        text: root.initialLoad ? "Scanning local agent history…"
                            : root.providers.length + " providers  ·  "
                                + (root.cycle?.sessions || 0) + " sessions this cycle"
                        color: Theme.subtle
                        font.family: Theme.displayFont
                        font.pixelSize: 10
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: AgentUsageData.snapshot.readAt !== undefined && AgentUsageData.snapshot.readAt !== ""
                    text: Fmt.ago(Date.parse(AgentUsageData.snapshot.readAt) / 1000)
                    color: Theme.muted
                    font.family: Theme.displayFont
                    font.pixelSize: 9
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.highlightLow
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: !root.initialLoad || root.windows.length > 0

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "TOKENS THIS CYCLE"
                        color: Theme.muted
                        font.family: Theme.displayFont
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: Fmt.tokens(root.totalTokens)
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }
                }

                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.highlightLow }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "TODAY"
                        color: Theme.muted
                        font.family: Theme.displayFont
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: Fmt.tokens(root.todayTokens)
                        color: Theme.iris
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                }

                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.highlightLow }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "EST. COST"
                        color: Theme.muted
                        font.family: Theme.displayFont
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: Fmt.usd(root.todayCost)
                        color: Theme.gold
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                }
            }

            ColumnLayout {
                visible: root.windows.length > 0
                Layout.fillWidth: true
                spacing: 7

                Text {
                    text: "Subscription limits"
                    color: Theme.foreground
                    font.family: Theme.displayFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: root.windows
                    delegate: StatBar {
                        required property var modelData
                        icon: "󰓅"
                        label: modelData.label
                        value: Math.round(modelData.usedPercent) + "% used · "
                            + modelData.remainingPercent + "% left"
                        fraction: Number(modelData.usedPercent) / 100
                        accent: root.limitColor(Number(modelData.remainingPercent))
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: !!root.cycle?.daily?.length
                Text {
                    text: "Recorded usage by provider"
                    color: Theme.foreground
                    font.family: Theme.displayFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "share of tokens"
                    color: Theme.muted
                    font.family: Theme.displayFont
                    font.pixelSize: 9
                }
            }

            Repeater {
                model: root.providers
                delegate: Rectangle {
                    id: providerCard
                    required property var modelData
                    required property int index
                    readonly property var modelRows: root.providerModels(modelData.id)
                    Layout.fillWidth: true
                    implicitHeight: cardBody.implicitHeight + 18
                    radius: 10
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.highlightLow

                    ColumnLayout {
                        id: cardBody
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 7

                            Text {
                                text: root.providerIcon(providerCard.modelData.id)
                                color: [Theme.iris, Theme.foam, Theme.gold, Theme.rose][providerCard.index % 4]
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                            }

                            Text {
                                text: providerCard.modelData.label
                                color: Theme.foreground
                                font.family: Theme.displayFont
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: (providerCard.modelData.sessions || providerCard.modelData.events || 0) + " sessions"
                                color: Theme.muted
                                font.family: Theme.displayFont
                                font.pixelSize: 9
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: Fmt.usd(providerCard.modelData.costUsd)
                                color: Theme.gold
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            Rectangle {
                                anchors.fill: parent
                                radius: 2
                                color: Theme.highlightLow
                            }
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1,
                                    Number(providerCard.modelData.totalTokens || 0) / Math.max(1, root.recordedTokens)))
                                height: parent.height
                                radius: 2
                                color: [Theme.iris, Theme.foam, Theme.gold, Theme.rose][providerCard.index % 4]
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: providerCard.modelRows.length > 0
                            text: providerCard.modelRows.map(m => m.model + "  ·  " + Fmt.tokens(m.totalTokens)).join("     ")
                            color: Theme.subtle
                            font.family: Theme.displayFont
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: providerCard.modelRows.length === 0
                            text: Fmt.tokens(providerCard.modelData.totalTokens || 0) + " recorded tokens"
                            color: Theme.subtle
                            font.family: Theme.displayFont
                            font.pixelSize: 9
                        }
                    }
                }
            }

            Text {
                visible: root.providers.length === 0 && root.windows.length === 0
                Layout.fillWidth: true
                text: AgentUsageData.loading ? "Loading agent activity…"
                    : AgentUsageData.lastError !== "" ? AgentUsageData.lastError
                    : "No agent activity recorded yet."
                wrapMode: Text.WordWrap
                color: AgentUsageData.lastError !== "" ? Theme.gold : Theme.subtle
                font.family: Theme.displayFont
                font.pixelSize: 10
            }

            Text {
                visible: AgentUsageData.lastError !== "" && (root.providers.length > 0 || root.windows.length > 0)
                Layout.fillWidth: true
                text: AgentUsageData.lastError
                wrapMode: Text.WordWrap
                color: Theme.gold
                font.family: Theme.displayFont
                font.pixelSize: 9
            }
        }
    }
}
