// material.dart traz Scaffold, AppBar, diálogos e o calendário.
import 'package:flutter/material.dart';

// Task e as funções de data (isSameDay, dateOnly, formatShortDate).
import '../models/task.dart';
// Lê a preferência "confirmar exclusão".
import '../services/app_storage.dart';
// Salva e carrega a lista de tarefas.
import '../services/task_storage.dart';
// Tela amigável quando não há tarefas naquele filtro/dia.
import '../widgets/empty_state.dart';
// Chips Todas / Pendentes / Concluídas.
import '../widgets/task_filter.dart';
// Campo de baixo para criar tarefa.
import '../widgets/task_input.dart';
// Cartão de uma tarefa.
import '../widgets/task_item.dart';
// Tela de configurações.
import 'settings_page.dart';

// HomePage é a tela principal e guarda o ESTADO da lista.
// StatefulWidget porque adicionar, concluir e excluir mudam a tela.
class HomePage extends StatefulWidget {
  // Função para voltar ao login, vinda do TodoApp.
  final VoidCallback onLogout;
  // Função para avisar o TodoApp que o tema mudou.
  final ValueChanged<bool> onThemeChanged;

  const HomePage({
    super.key,
    required this.onLogout,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Objeto que grava/lê as tarefas no aparelho.
  final TaskStorage _storage = TaskStorage();
  // Objeto que lê as configurações (confirmar exclusão).
  final AppStorage _appStorage = AppStorage();

  // Lista em memória. É ela que a interface mostra.
  List<Task> _tasks = [];

  // Dia que o aluno está olhando agora. Começa em hoje, sem hora.
  DateTime _selectedDate = dateOnly(DateTime.now());

  // Filtro ativo: 'all', 'pending' ou 'completed'.
  String _selectedFilter = 'all';

  // Se true, a exclusão pede "Tem certeza?".
  bool _confirmDelete = true;

  // true enquanto as tarefas estão sendo lidas do disco.
  bool _isLoading = true;

  // get cria uma propriedade calculada: não fica guardada, é montada na hora.
  // Aqui pegamos só as tarefas do dia selecionado.
  List<Task> get _tasksOnSelectedDate {
    return _tasks
        // where filtra. isSameDay compara só o dia, sem hora.
        .where((task) => isSameDay(task.date, _selectedDate))
        .toList();
  }

  // Tarefas do dia + filtro de status, já ordenadas.
  List<Task> get _visibleTasks {
    // Primeiro ficamos só com o dia escolhido.
    final ofDay = _tasksOnSelectedDate;
    // Lista que vamos preencher conforme o filtro.
    List<Task> filtered;

    // Pendentes: isCompleted == false.
    if (_selectedFilter == 'pending') {
      filtered = ofDay.where((task) => !task.isCompleted).toList();
    // Concluídas: isCompleted == true.
    } else if (_selectedFilter == 'completed') {
      filtered = ofDay.where((task) => task.isCompleted).toList();
    } else {
      // 'all': copia a lista do dia sem tirar ninguém.
      filtered = List<Task>.from(ofDay);
    }

    // sort organiza. 0 = iguais, 1 = a vai depois, -1 = a vai antes.
    // Pendentes primeiro, concluídas depois.
    // sort é estável: a ordem de criação se mantém dentro de cada grupo.
    filtered.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        return 0;
      }
      return a.isCompleted ? 1 : -1;
    });

    return filtered;
  }

  // Quantas tarefas do DIA estão pendentes. Usado no cartão e no texto.
  int get _pendingCount =>
      _tasksOnSelectedDate.where((task) => !task.isCompleted).length;

  // Quantas tarefas do DIA estão concluídas.
  int get _completedCount =>
      _tasksOnSelectedDate.where((task) => task.isCompleted).length;

  // Título curto: Hoje, Ontem, Amanhã ou "Tarefas do dia".
  String get _dayTitle {
    final today = dateOnly(DateTime.now());
    if (isSameDay(_selectedDate, today)) {
      return 'Hoje';
    }
    if (isSameDay(_selectedDate, today.subtract(const Duration(days: 1)))) {
      return 'Ontem';
    }
    if (isSameDay(_selectedDate, today.add(const Duration(days: 1)))) {
      return 'Amanhã';
    }
    return 'Tarefas do dia';
  }

  // Data por extenso: "8 de setembro de 2026".
  String get _longDateLabel {
    // Lista dos meses em português. Índice 0 = janeiro.
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    // month vai de 1 a 12; a lista começa em 0, por isso month - 1.
    return '${_selectedDate.day} de ${months[_selectedDate.month - 1]} de ${_selectedDate.year}';
  }

  // Mensagem do EmptyState, conforme o filtro.
  String get _emptyMessage {
    if (_selectedFilter == 'pending') {
      return 'Nenhuma tarefa pendente neste dia.';
    }
    if (_selectedFilter == 'completed') {
      return 'Nenhuma tarefa concluída neste dia.';
    }
    return 'Você ainda não possui tarefas neste dia.\nAdicione uma tarefa para começar.';
  }

  // Frase do cabeçalho com singular/plural.
  String get _pendingMessage {
    if (_pendingCount == 1) {
      return 'Você tem 1 tarefa pendente';
    }
    return 'Você tem $_pendingCount tarefas pendentes';
  }

  // initState roda uma vez, quando a Home nasce.
  @override
  void initState() {
    super.initState();
    // Carrega tarefas e configurações salvas.
    _loadData();
  }

  Future<void> _loadData() async {
    // Lê a lista JSON e transforma em List<Task>.
    final loadedTasks = await _storage.loadTasks();
    // Lê se devemos pedir confirmação para excluir.
    final settings = await _appStorage.loadSettings();

    // setState redesenha a tela com os dados novos.
    setState(() {
      _tasks = loadedTasks;
      _confirmDelete = settings.confirmDelete;
      _isLoading = false;
    });
  }

  // Grava a lista inteira de novo no aparelho.
  Future<void> _saveTasks() async {
    await _storage.saveTasks(_tasks);
  }

  // Cria uma tarefa, coloca na lista, salva e mostra o dia dela.
  Future<void> _addTask(String title, DateTime date) async {
    final task = Task(
      // millisecondsSinceEpoch é um número único o bastante para a aula.
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: dateOnly(date),
    );

    setState(() {
      // add coloca no final da lista.
      _tasks.add(task);
      // Troca o dia da Home para o dia da tarefa recém-criada.
      _selectedDate = dateOnly(date);
    });

    await _saveTasks();
  }

  // Inverte concluída ↔ pendente e salva.
  Future<void> _toggleTask(Task task) async {
    setState(() {
      // ! inverte o bool: true vira false, false vira true.
      task.isCompleted = !task.isCompleted;
    });

    await _saveTasks();
  }

  // Exclui a tarefa. Pode pedir confirmação, conforme a configuração.
  Future<void> _deleteTask(Task task) async {
    if (_confirmDelete) {
      // showDialog<bool> devolve true (excluir) ou false (cancelar).
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Excluir tarefa?'),
            content: const Text(
              'Tem certeza que deseja excluir esta tarefa?',
            ),
            actions: [
              TextButton(
                // pop fecha o diálogo e devolve false.
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                // pop fecha o diálogo e devolve true.
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          );
        },
      );

      // Se cancelou ou fechou o diálogo, paramos aqui.
      if (shouldDelete != true) {
        return;
      }
    }

    setState(() {
      // removeWhere tira da lista o item com o mesmo id.
      _tasks.removeWhere((item) => item.id == task.id);
    });
    await _saveTasks();
  }

  // Troca o dia selecionado e redesenha a lista.
  void _changeDate(DateTime date) {
    setState(() {
      _selectedDate = dateOnly(date);
    });
  }

  // Abre o calendário para pular para qualquer dia.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    // null = o aluno cancelou o calendário.
    if (picked != null) {
      _changeDate(picked);
    }
  }

  // Abre a tela de configurações. Quando voltar, relê "confirmar exclusão".
  Future<void> _openSettings() async {
    // Navigator.push empilha a SettingsPage em cima da Home.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SettingsPage(
            onLogout: widget.onLogout,
            onThemeChanged: widget.onThemeChanged,
          );
        },
      ),
    );

    // Quando o aluno volta, a configuração pode ter mudado.
    final settings = await _appStorage.loadSettings();
    // Se a Home já saiu da árvore (logout), não usamos o context.
    if (!mounted) {
      return;
    }
    setState(() {
      _confirmDelete = settings.confirmDelete;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas tarefas'),
        // actions são os botões do lado direito da AppBar.
        actions: [
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      // Se ainda está carregando, mostra a rodinha. Senão, a lista + o campo.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Expanded faz a lista ocupar o espaço que sobrar.
                Expanded(child: _buildContent()),
                // O campo de adicionar fica fixo embaixo.
                TaskInput(
                  selectedDate: _selectedDate,
                  onAdd: _addTask,
                ),
              ],
            ),
    );
  }

  // Cabeçalho: Hoje + data por extenso + frase de pendentes.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Align(
        // Alinha o bloco à esquerda.
        alignment: Alignment.centerLeft,
        child: Column(
          // Filhos alinhados à esquerda.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _longDateLabel,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _pendingMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Setas < > e o botão do calendário com a data curta.
  Widget _buildDateNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Dia anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              // subtract tira 1 dia da data atual.
              _changeDate(_selectedDate.subtract(const Duration(days: 1)));
            },
          ),
          // Expanded deixa o botão do meio ocupar o espaço central.
          Expanded(
            child: TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(formatShortDate(_selectedDate)),
            ),
          ),
          IconButton(
            tooltip: 'Próximo dia',
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              // add soma 1 dia.
              _changeDate(_selectedDate.add(const Duration(days: 1)));
            },
          ),
        ],
      ),
    );
  }

  // Os dois cartões: Pendentes e Concluídas (só do dia selecionado).
  Widget _buildIndicators(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Pendentes',
              count: _pendingCount,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'Concluídas',
              count: _completedCount,
            ),
          ),
        ],
      ),
    );
  }

  // Decide: lista vazia (scroll único) ou cabeçalho fixo + lista rolável.
  Widget _buildContent() {
    if (_visibleTasks.isEmpty) {
      // ListView inteiro evita overflow em janelas baixas.
      return ListView(
        children: [
          _buildHeader(context),
          _buildDateNav(),
          TaskFilter(
            selectedFilter: _selectedFilter,
            onChanged: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
          ),
          _buildIndicators(context),
          EmptyState(message: _emptyMessage),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(context),
        _buildDateNav(),
        TaskFilter(
          selectedFilter: _selectedFilter,
          onChanged: (value) {
            setState(() {
              _selectedFilter = value;
            });
          },
        ),
        _buildIndicators(context),
        // A lista de tarefas ocupa o resto da tela e rola sozinha.
        Expanded(child: _buildTaskList()),
      ],
    );
  }

  // ListView.builder cria os itens sob demanda, um por índice.
  Widget _buildTaskList() {
    final visibleTasks = _visibleTasks;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      // Quantos cartões a lista tem.
      itemCount: visibleTasks.length,
      // itemBuilder é chamado para cada posição (0, 1, 2...).
      itemBuilder: (context, index) {
        final task = visibleTasks[index];

        return TaskItem(
          task: task,
          // () => ... cria uma função que chama o método com ESTA tarefa.
          onToggle: () => _toggleTask(task),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }
}

// Cartão pequeno de resumo, usado só nesta página (por isso o _).
class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;

  const _SummaryCard({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      // Cor de fundo um pouco diferente da tela, para o cartão destacar.
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              // '$count' transforma o número em texto.
              '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}