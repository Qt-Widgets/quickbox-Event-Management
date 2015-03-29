#include "competitorsplugin.h"
#include "thispartwidget.h"
#include "competitordocument.h"
#include "registrationswidget.h"

//#include <EventPlugin/eventplugin.h>

#include <qf/qmlwidgets/framework/mainwindow.h>
#include <qf/qmlwidgets/framework/dockwidget.h>
#include <qf/qmlwidgets/action.h>
#include <qf/qmlwidgets/menubar.h>

//#include <qf/core/log.h>

#include <QQmlEngine>

namespace qfw = qf::qmlwidgets;
namespace qff = qf::qmlwidgets::framework;
//namespace qfd = qf::qmlwidgets::dialogs;
//namespace qfs = qf::core::sql;

CompetitorsPlugin::CompetitorsPlugin(QObject *parent)
	: Super(parent)
{
	connect(this, &CompetitorsPlugin::installed, this, &CompetitorsPlugin::onInstalled, Qt::QueuedConnection);
}

CompetitorsPlugin::~CompetitorsPlugin()
{
	if(m_registrationsDockWidget)
		m_registrationsDockWidget->savePersistentSettingsRecursively();
}

QObject *CompetitorsPlugin::createCompetitorDocument(QObject *parent)
{
	CompetitorDocument *ret = new CompetitorDocument(parent);
	if(!parent) {
		qfWarning() << "Parent is NULL, created class will have QQmlEngine::JavaScriptOwnership.";
		qmlEngine()->setObjectOwnership(ret, QQmlEngine::JavaScriptOwnership);
	}
	return ret;
}

void CompetitorsPlugin::onInstalled()
{
	qff::MainWindow *fwk = qff::MainWindow::frameWork();
	m_partWidget = new ThisPartWidget();
	fwk->addPartWidget(m_partWidget, manifest()->featureId());
	{
		qfw::Action *a = new qfw::Action("Show registrations");
		a->setCheckable(true);
		a->setShortcut("ctrl+shift+R");
		//fwk->menuBar()->actionForPath("tools/pluginSettings")->addActionInto(actConfigureLogging);
		fwk->menuBar()->actionForPath("view")->addActionInto(a);
		connect(a, &qfw::Action::triggered, this, &CompetitorsPlugin::setRegistrationsDockVisible);
	}
	emit nativeInstalled();
}

void CompetitorsPlugin::setRegistrationsDockVisible(bool on)
{
	if(on && !m_registrationsDockWidget) {
		m_registrationsDockWidget = new qff::DockWidget(nullptr);
		m_registrationsDockWidget->setObjectName("registrationsDockWidget");
		auto rw = new RegistrationsWidget();
		m_registrationsDockWidget->setWidget(rw);
		qff::MainWindow *fwk = qff::MainWindow::frameWork();
		fwk->addDockWidget(Qt::RightDockWidgetArea, m_registrationsDockWidget);
		rw->reload();
		m_registrationsDockWidget->loadPersistentSettingsRecursively();
	}
	if(m_registrationsDockWidget)
		//if(on) {
		//	auto rw = qobject_cast<RegistrationsWidget*>(m_registrationsDockWidget->widget());
		//	rw->reload();
		//}
		m_registrationsDockWidget->setVisible(on);
}
