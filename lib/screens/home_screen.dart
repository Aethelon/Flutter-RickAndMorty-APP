import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/character_card.dart';
import '../widgets/episode_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/location_card.dart';
import '../widgets/detail_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  late ScrollController scrollController;
  bool isInitialized = false;

  late TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    scrollController = ScrollController();
    _searchController = TextEditingController();

    scrollController.addListener(handleScroll);
    tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isInitialized) {
      isInitialized = true;
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadContent();
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void handleScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent * 0.8) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadContent();
    }
  }

  void handleTabChange(int index) {
    _searchController.clear();

    final provider = Provider.of<AppProvider>(context, listen: false);
    ContentType type = ContentType.values[index];
    provider.switchContentType(type);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    const double appBarItemHeight = 50.0;
    final double verticalMargin = (AppBar().preferredSize.height - appBarItemHeight) / 2;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: appBarItemHeight,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              hintText: 'Buscar por nome...',
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                provider.setSearchQuery(value);
              });
            },
          ),
        ),
        actions: [
          Container(
            width: appBarItemHeight,
            height: appBarItemHeight,
            margin: EdgeInsets.symmetric(vertical: verticalMargin, horizontal: 4.0),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              color: Colors.white,
              tooltip: 'Filtros',
              onPressed: () {
                _showFilterModal(context);
              },
            ),
          ),
          Container(
            width: appBarItemHeight,
            height: appBarItemHeight,
            margin: EdgeInsets.only(top: verticalMargin, bottom: verticalMargin, left: 4.0, right: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              color: Colors.white,
              tooltip: 'Sobre o projeto',
              onPressed: () {
                _showAboutDialog(context);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return buildBody(provider);
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: NavigationBar(
                height: 65,
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                selectedIndex: tabController.index,
                onDestinationSelected: (index) {
                  tabController.animateTo(index);
                  handleTabChange(index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.theater_comedy_outlined),
                    selectedIcon: Icon(Icons.theater_comedy),
                    label: 'Personagens',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tv_outlined),
                    selectedIcon: Icon(Icons.tv),
                    label: 'Episódios',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.location_on_outlined),
                    selectedIcon: Icon(Icons.location_on),
                    label: 'Locais',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final githubUrl = Uri.parse('https://github.com/Aethelon/Flutter-RickAndMorty-APP');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sobre o Projeto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Versão: 1.0.0'),
              const SizedBox(height: 16),
              const Text('Desenvolvido por:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Bruno Magno'),
              const Text('Leandro Oliveira'),
              const Text('Paulo de Araújo'),
              const Text('Marcelo Mesquita'),
              const SizedBox(height: 16),
              InkWell(
                child: Text(
                  'Ver código no GitHub',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () async {
                  if (await canLaunchUrl(githubUrl)) {
                    await launchUrl(githubUrl);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                switch (provider.currentType) {
                  case ContentType.characters:
                    return _buildCharacterFilters(context, provider);
                  case ContentType.locations:
                    return _buildLocationFilters(context, provider);
                  case ContentType.episodes:
                    return _buildEpisodeFilters(context, provider);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterFilters(BuildContext context, AppProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        RadioListTile<String?>(
          title: const Text('Todos'), value: null, groupValue: provider.statusFilter,
          onChanged: (v) => provider.setStatusFilter(v),
        ),
        RadioListTile<String>(
          title: const Text('Vivo'), value: 'alive', groupValue: provider.statusFilter,
          onChanged: (v) => provider.setStatusFilter(v),
        ),
        RadioListTile<String>(
          title: const Text('Morto'), value: 'dead', groupValue: provider.statusFilter,
          onChanged: (v) => provider.setStatusFilter(v),
        ),
        RadioListTile<String>(
          title: const Text('Desconhecido'), value: 'unknown', groupValue: provider.statusFilter,
          onChanged: (v) => provider.setStatusFilter(v),
        ),
        const Divider(),
        const Text('Gênero', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        RadioListTile<String?>(
          title: const Text('Todos'), value: null, groupValue: provider.genderFilter,
          onChanged: (v) => provider.setGenderFilter(v),
        ),
        RadioListTile<String>(
          title: const Text('Feminino'), value: 'female', groupValue: provider.genderFilter,
          onChanged: (v) => provider.setGenderFilter(v),
        ),
        RadioListTile<String>(
          title: const Text('Masculino'), value: 'male', groupValue: provider.genderFilter,
          onChanged: (v) => provider.setGenderFilter(v),
        ),
        RadioListTile<String>(
          title: const Text('Sem Gênero'), value: 'genderless', groupValue: provider.genderFilter,
          onChanged: (v) => provider.setGenderFilter(v),
        ),
        RadioListTile<String>(
          title: const Text('Desconhecido'), value: 'unknown', groupValue: provider.genderFilter,
          onChanged: (v) => provider.setGenderFilter(v),
        ),
        const Divider(),
        const Text('Espécie (ex: Human, Alien)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextFormField(
          initialValue: provider.speciesFilter,
          decoration: const InputDecoration(hintText: 'Digite a espécie...'),
          onFieldSubmitted: (value) {
            provider.setSpeciesFilter(value.isEmpty ? null : value);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLocationFilters(BuildContext context, AppProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo (ex: Planet, Cluster)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextFormField(
          initialValue: provider.locationTypeFilter,
          decoration: const InputDecoration(hintText: 'Digite o tipo...'),
          onFieldSubmitted: (value) {
            provider.setLocationTypeFilter(value.isEmpty ? null : value);
            Navigator.pop(context);
          },
        ),
        const Divider(),
        const Text('Dimensão (ex: C-137)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextFormField(
          initialValue: provider.locationDimensionFilter,
          decoration: const InputDecoration(hintText: 'Digite a dimensão...'),
          onFieldSubmitted: (value) {
            provider.setLocationDimensionFilter(value.isEmpty ? null : value);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEpisodeFilters(BuildContext context, AppProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Código do Episódio (ex: S01E01)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextFormField(
          initialValue: provider.episodeCodeFilter,
          decoration: const InputDecoration(hintText: 'Digite o código...'),
          onFieldSubmitted: (value) {
            provider.setEpisodeCodeFilter(value.isEmpty ? null : value);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildBody(AppProvider provider) {
    if (provider.isLoading &&
        provider.characters.isEmpty &&
        provider.episodes.isEmpty &&
        provider.locations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.errorMessage != null &&
        provider.characters.isEmpty &&
        provider.episodes.isEmpty &&
        provider.locations.isEmpty) {
      return buildErrorWidget(provider.errorMessage!);
    }

    return Column(
      children: [
        Expanded(
          child: buildContentGrid(provider),
        ),
      ],
    );
  }

  Widget buildContentGrid(AppProvider provider) {
    final crossAxisCount = calculateCrossAxisCount(context);
    const gridPadding = EdgeInsets.fromLTRB(8, 8, 8, 85);

    if (provider.currentType == ContentType.characters) {
      if (provider.characters.isEmpty) {
        return buildEmptyState();
      }

      final bool hasMore = provider.hasNextPage;
      final int itemCount = provider.characters.length + (hasMore ? 1 : 0);

      return GridView.builder(
        controller: scrollController,
        padding: gridPadding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == provider.characters.length && hasMore) {
            return buildLoadingIndicator();
          }

          final character = provider.characters[index];
          return CharacterCard(
            character: character,
            onTap: () {
              openDetailDialog(character, 'character');
            },
          );
        },
      );
    } else if (provider.currentType == ContentType.episodes) {
      if (provider.episodes.isEmpty) {
        return buildEmptyState();
      }

      final bool hasMore = provider.hasNextPage;
      final int itemCount = provider.episodes.length + (hasMore ? 1 : 0);

      return GridView.builder(
        controller: scrollController,
        padding: gridPadding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == provider.episodes.length && hasMore) {
            return buildLoadingIndicator();
          }
          final episode = provider.episodes[index];
          return EpisodeCard(
            episode: episode,
            onTap: () {
              openDetailDialog(episode, 'episode');
            },
          );
        },
      );
    } else {
      if (provider.locations.isEmpty) {
        return buildEmptyState();
      }

      final bool hasMore = provider.hasNextPage;
      final int itemCount = provider.locations.length + (hasMore ? 1 : 0);

      return GridView.builder(
        controller: scrollController,
        padding: gridPadding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == provider.locations.length && hasMore) {
            return buildLoadingIndicator();
          }
          final location = provider.locations[index];
          return LocationCard(
            location: location,
            onTap: () {
              openDetailDialog(location, 'location');
            },
          );
        },
      );
    }
  }

  void openDetailDialog(dynamic item, String type) {
    showDialog(
      context: context,
      builder: (context) {
        return DetailDialog(
          item: item,
          type: type,
        );
      },
    );
  }

  int calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 1200) {
      return 4;
    } else if (width > 800) {
      return 3;
    } else {
      return 2;
    }
  }

  Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget buildEmptyState() {
    return const Center(
      child: Text(
        'Nenhum item encontrado',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<AppProvider>(context, listen: false);
                provider.switchContentType(provider.currentType);
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
