import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    index: 4
    
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            spacing: 4
            F1Label { text: "DRIVERS' CHAMPIONSHIP" }
            Repeater {
                model: F1Data.driverStandings.slice(0, 10)
                F1PointsRow {
                    required property var modelData
                    position: Number(modelData.position)
                    name: modelData.Driver.givenName + " " + modelData.Driver.familyName
                    points: Number(modelData.points)
                    leader: Number(F1Data.driverStandings[0]?.points ?? 1)
                    tint: F1Data.driverColour(modelData.Driver.code)
                    logo: F1Data.teamLogo(modelData.Constructors[modelData.Constructors.length - 1]?.constructorId)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            spacing: 4
            F1Label { text: "CONSTRUCTORS' CHAMPIONSHIP" }
            Repeater {
                model: F1Data.teamStandings.slice(0, 10)
                F1PointsRow {
                    required property var modelData
                    position: Number(modelData.position)
                    name: modelData.Constructor.name
                    points: Number(modelData.points)
                    leader: Number(F1Data.teamStandings[0]?.points ?? 1)
                    tint: F1Data.teamColour(modelData.Constructor.constructorId)
                    logo: F1Data.teamLogo(modelData.Constructor.constructorId)
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
