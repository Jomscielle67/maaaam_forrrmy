import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _bannerImage = [];

  getBanners() {
    _firestore.collection('banners').get().then((querySnapshot) {
      _bannerImage.clear();
      for (var doc in querySnapshot.docs) {
        if (mounted) {
          setState(() {
            _bannerImage.add(doc['image']);
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getBanners();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            _bannerImage.isEmpty
                ? Center(child: CircularProgressIndicator())
                : PageView.builder(
                  itemCount: _bannerImage.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: _bannerImage[index],
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Shimmer(
                            duration: Duration(seconds: 3), //Default value
                            interval: Duration(seconds: 5), //Default value: Duration(seconds: 0)
                            color: Colors.white, //Default value
                            colorOpacity: 0, //Default value
                            enabled: true, //Default value
                            direction: ShimmerDirection.fromLTRB(),  //Default Value
                            child: Container(
                              color: Colors.deepPurple,
                            ),
                          ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
