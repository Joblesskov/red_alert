#include "path://media/packages/vanilla/scripts"
// --------------------------------------------
// TODO: replace with your package's script folder here
// --------------------------------------------
#include "path://media/packages/red_alert/scripts"

#include "my_gamemode.as"

// --------------------------------------------
void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);

	UserSettings settings;
	settings.fromXmlElement(inputSettings);
	_setupLog(inputSettings);
	settings.print();

	// --------------------------------------------
	// TODO: replace with your package's folder here
	// --------------------------------------------
	// array<string> overlays = {
    //             "media/packages/red_alert"
    //     };
    //     settings.m_overlayPaths = overlays;

	MyGameMode metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
