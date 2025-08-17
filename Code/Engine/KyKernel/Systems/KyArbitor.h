/*
    This code is part of Kyshutsu Engine.

    Copyright (c) 2020-2025 WD Studios Corp. and/or its licensors. All rights reserved in
    all media. The coded instructions, statements, computer programs, and/or related
    material (collectively the "Data") in these files are under the MIT License.
*/

#include <KyKernel/KyKernelDLL.h>


namespace kyshutsu {

    /*
    * @author Mikael K. Aboagye
    * @brief Arbitor class for managing arbitration between different systems.
    *
    * This class is responsible for coordinating access to shared resources
    * and ensuring that conflicting requests are handled appropriately.
    * 
    * It also manages lifecycles between other applications (e.g. plugins, engine editor depends on KyRenderEngine, which is its own instance that communicates over a IPC.)
    *
    * @warning You need to create one instance of this class, preferably within the main application. 
    * It can be a "child" instance of another arbitor class. this is useful for launching the game/application from the editor, into its own window.
    */
    class NS_KYKERNEL_DLL Arbitor
    {
        NS_DISALLOW_COPY_AND_ASSIGN(Arbitor);

        /*
        * @brief Initializes the arbitor instance. call this after you queue any needed plugins.
        * @param pParentArbitor Pointer to the parent arbitor instance, if any.
        */
        void InitArbitor(kyshutsu::Arbitor* pParentArbitor = nullptr);

        /*
        * @brief Shuts down the arbitor instance.
        * @param bReplicateShutdown Whether to replicate the shutdown to child arbitor instances. this will also shut them down as well. do this when the editor is shutting down.
        */
        void ShutdownArbitor(bool bReplicateShutdown = false);

        bool IsInitialized() const { return m_bIsInitialized; }

        void QueuePlugin(const char* pPluginName);
        /*
        * @brief Subscribes an application to the arbitor. This allows the application to receive and send IPC Messages to the arbitor.
        * @param pAppName Pointer to the application name.
        */
        void SubscribeApplication(const char* pAppName);

        /*
        * @brief Removes an application from the arbitor. This prevents the application from receiving IPC Messages from the arbitor.
        * @param pAppName Pointer to the application name.
        */
        void RemoveApplication(const char* pAppName);

        /*
        * @brief Starts up the arbitor instance. you are responsible for initializing any necessary resources and starting any required threads.
        */
        virtual void Startup() = 0;

        /*
        * @brief Shuts down the arbitor instance. you are responsible for cleaning up any resources and stopping any running threads.
        */
        virtual void Shutdown() = 0;
    private:
        bool m_bIsInitialized = false;
        nsHybridArray<const char*, 3> m_hbPluginList;
        nsHybridArray<const char*, 3> m_hbAppList;
    };
}
