import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../models/episode_model.dart';
import '../models/location_model.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class DetailDialog extends StatelessWidget {
  final dynamic item;
  final String type;

  const DetailDialog({
    super.key,
    required this.item,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildHeader(context),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            getTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget buildContent(BuildContext context) {
    if (type == 'character') {
      return buildCharacterContent(context, item as Character);
    } else if (type == 'episode') {
      return buildEpisodeContent(context, item as Episode);
    } else {
      return buildLocationContent(context, item as LocationModel);
    }
  }

  String getTitle() {
    if (type == 'character') {
      return (item as Character).name;
    } else if (type == 'episode') {
      return (item as Episode).name;
    } else {
      return (item as LocationModel).name;
    }
  }

  Widget buildCharacterContent(BuildContext context, Character character) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              character.image,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        buildDetailRow('Status', character.status),
        buildDetailRow('Espécie', character.species),
        if (character.type.isNotEmpty) buildDetailRow('Tipo', character.type),
        buildDetailRow('Gênero', character.gender),
        buildDetailRow('Origem', character.origin.name),
        buildDetailRow('Localização', character.location.name),
        const SizedBox(height: 16),
        const Text(
          'Episódios',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        buildRelatedEpisodesList(context, character.episode),
      ],
    );
  }

  Widget buildEpisodeContent(BuildContext context, Episode episode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDetailRow('Código', episode.episode),
        buildDetailRow('Data de exibição', episode.airDate),
        buildDetailRow('Total de personagens', episode.characters.length.toString()),
        const SizedBox(height: 16),
        const Text(
          'Personagens',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        buildRelatedCharactersList(context, episode.characters),
      ],
    );
  }

  Widget buildLocationContent(BuildContext context, LocationModel location) { 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDetailRow('Tipo', location.type),
        buildDetailRow('Dimensão', location.dimension),
        buildDetailRow('Total de residentes', location.residents.length.toString()),
        const SizedBox(height: 16),
        const Text(
          'Residentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        buildRelatedCharactersList(context, location.residents),
      ],
    );
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRelatedCharactersList(BuildContext context, List<String> urls) {
    if (urls.isEmpty) {
      return const Text('Nenhum personagem encontrado');
    }

    final apiService = ApiService();
    final provider = Provider.of<AppProvider>(context, listen: false);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        final id = apiService.extractIdFromUrl(urls[index]);

        return FutureBuilder<Character>(
          future: provider.getCharacterById(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Carregando...'),
              );
            }

            if (snapshot.hasError) {
              return const ListTile(
                leading: Icon(Icons.error),
                title: Text('Erro ao carregar'),
              );
            }

            final character = snapshot.data!;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(character.image),
              ),
              title: Text(character.name),
              subtitle: Text('${character.status} - ${character.species}'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => DetailDialog(
                    item: character,
                    type: 'character',
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildRelatedEpisodesList(BuildContext context, List<String> urls) {
    if (urls.isEmpty) {
      return const Text('Nenhum episódio encontrado');
    }

    final apiService = ApiService();
    final provider = Provider.of<AppProvider>(context, listen: false);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        final id = apiService.extractIdFromUrl(urls[index]);

        return FutureBuilder<Episode>(
          future: provider.getEpisodeById(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Carregando...'),
              );
            }

            if (snapshot.hasError) {
              return const ListTile(
                leading: Icon(Icons.error),
                title: Text('Erro ao carregar'),
              );
            }

            final episode = snapshot.data!;
            return ListTile(
              leading: CircleAvatar(
                child: Text(episode.episode.split('E').last),
              ),
              title: Text(episode.name),
              subtitle: Text(episode.airDate),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => DetailDialog(
                    item: episode,
                    type: 'episode',
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
