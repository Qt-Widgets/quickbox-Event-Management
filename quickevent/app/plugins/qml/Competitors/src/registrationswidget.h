#ifndef REGISTRATIONSWIDGET_H
#define REGISTRATIONSWIDGET_H

#include <QWidget>

namespace Ui {
class RegistrationsWidget;
}
namespace qf {
namespace core {
namespace model {
class SqlTableModel;
}
}
}

class RegistrationsWidget : public QWidget
{
	Q_OBJECT

public:
	explicit RegistrationsWidget(QWidget *parent = 0);
	~RegistrationsWidget();

	void reload();
private:
	void onFilterTextChanged();
	void onGrpFilterToggled();
private:
	Ui::RegistrationsWidget *ui;
	qf::core::model::SqlTableModel *m_registrationsModel;
};

#endif // REGISTRATIONSWIDGET_H
