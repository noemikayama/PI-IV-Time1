// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 30/10/2026 - Dashboard Trainer com alternância entre cavalos próprios e painel profissional.
import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/trainer_sidebar.dart';
import 'package:horse_life/features/home/data/models/trainer_home_data.dart';
import '../../widgets/dashboard_text_styles.dart';
import '../../widgets/dashboard_training_content.dart';
import '../../widgets/trainer_professional_content.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key,required this.onLogout,this.onHome,
    this.homeFuture,this.empty = false});
  final Future<void> Function() onLogout;
  final VoidCallback? onHome;
  final Future<TrainerHomeData>? homeFuture;
  final bool empty;
  @override
  State<TrainerDashboardScreen> createState()=>_TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  bool _professional=false;
  late Future<TrainerHomeData> _mockFuture;
  @override
  void initState() {
    super.initState();
    _mockFuture=Future.value(const TrainerHomeData(
      trainerName:'Treinador (mock)',specialty:null,todayTrainings:[],weeklyFeedbacksDone:0,
      weeklyFeedbacksTotal:0,activePlans:7,weeklyTrainingsCompleted:0,
      weeklyTrainingsPlanned:0,createdExercises:16,horses:[],totalLinkedHorses:12,clients:[]));
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    backgroundColor:Theme.of(context).scaffoldBackgroundColor,
    appBar:const HomeAppBar(),
    drawer:TrainerSidebar(onLogout:widget.onLogout,homeFuture:widget.homeFuture ?? _mockFuture),
    bottomNavigationBar:HomeBottomNavBar(selectedIndex:3,onItemSelected:(index){
      if(index==0){if(widget.onHome!=null){widget.onHome!();}else{Navigator.of(context).maybePop();}}
    }),
    body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:540),
      child:ListView(padding:const EdgeInsets.fromLTRB(20,20,20,32),children:[
        Text('Evolução',textAlign:TextAlign.center,style:DashboardTextStyles.pageTitle(context)),
        const SizedBox(height:24),
        Row(children:[
          Switch(value:_professional,activeColor:Colors.white,
            activeTrackColor:const Color(0xFF027068),
            onChanged:(value)=>setState(()=>_professional=value)),
          const SizedBox(width:8),
          const Flexible(child:Text('Painel profissional',style:TextStyle(fontFamily:'Urbanist',fontSize:20))),
        ]),
        const SizedBox(height:18),
        if(_professional)
          TrainerProfessionalContent(forceEmpty:widget.empty)
        else
          DashboardTrainingContent(empty:widget.empty),
      ]))),
  );
}
